require "base64"
require "openssl"
require "zlib"
require "javabean_xml"


class TrubyLicense
  class TrubyException < Exception ; end
  class PrivateKeyNeeded < TrubyException ; end
  class InvalidLicense < TrubyException ; end
  class InvalidPassword < TrubyException ; end

  LicenseData = Struct.new  :consumerType,
                            :notBefore,
                            :notAfter,
                            :extra,
                            :subject,
                            :holder,
                            :issued,
                            :issuer

  X500Principal = Struct.new :name

  # Creates an instance able to read and write licenses using the
  # supplied password and key. For writing licenses the key needs to be a
  # private key, otherwise a public key will do.
  def initialize password, key
    raise ArgumentError.new("password must be a String") unless password.is_a? String
    raise ArgumentError.new("key must be an OpenSSL DSA key") unless key.is_a? OpenSSL::PKey::DSA
    @password = password
    @key = key

    # to hold the ciphers used in the crypt method
    @cipher ||= {}

    # some extra parameters TrueLicense uses
    @iterations = 2005
    @salt = "\xCE\xFB\xDE\xAC\x05\x02\x19q"
  end

  def deserialize_license license_blob
    begin
      license_data = gunzip(decrypt(license_blob))
    rescue OpenSSL::Cipher::CipherError
      raise InvalidPassword.new "Could not decrypt license blob"
    rescue Zlib::GzipFile::Error
      raise InvalidLicense.new "Invalid format of license blob: not gzipped corrrectly"
    end


    JavabeanXml.from_xml license_data,

      :string => lambda { |value, properties| value },
      "de.schlichtherle.xml.GenericCertificate" => lambda { |v, properties|
        sig = b64d(properties[:signature])
        license =properties[:encoded]
        algorithm = properties[:signatureAlgorithm]
        encoding = properties[:signatureEncoding]
        unless algorithm == "SHA1withDSA"
          raise NotImplementedError.new(
                  "signature algorithm %s has not been implemented".
                  % algorithm
                )
        end
        unless encoding == "US-ASCII/Base64"
          raise NotImplementedError.new(
                  "signature encoding %s has not been implemented".
                  % encoding
                )
        end
        unless verify_signature(license, sig)
          raise InvalidLicense.new("License signature mismatch")
        end
        JavabeanXml.from_xml(license,
          :long => lambda { |value, p| value.to_i },
          :string => lambda { |value, p| value },
          "java.util.Date" => lambda { |value, p| Time.at(value / 1000) },
          "javax.security.auth.x500.X500Principal" => lambda { |value, p| X500Principal.new value },
          "de.schlichtherle.license.LicenseContent" => lambda {|value, properties|
            ld = LicenseData.new
            ld.members.each do |prop|
              ld[prop] = properties[prop.to_sym]
            end
            ld
          }
        )
      }

  end

  def serialize_license license_data
    lic_data = license_data.clone # allows us to make changes
    unless @key.private?
      raise PrivateKeyNeeded.new("Cannot use a public key to encrypt the license")
    end
    # make sure issuer and holder are properly wrapped in X500Principal objects
    [:issuer, :holder].each do |prop|
      if lic_data[prop].is_a? String
        lic_data[prop] = X500Principal.new lic_data[prop]
      end
    end
    lic_data.consumerType = lic_data.consumerType.to_s
    inner = JavabeanXml.to_xml lic_data,
                LicenseData => lambda { |value|
                  {
                    :class => "de.schlichtherle.license.LicenseContent",
                    :properties =>  lic_data.members.inject({}) {|props, prop|
                                      props[prop.to_sym] = lic_data[prop]
                                      props
                                    }
                  }
                },
                X500Principal => lambda { |value|
                  {
                    :class => "javax.security.auth.x500.X500Principal",
                    :value => {
                      :class => :string,
                      :value => value.name
                    }
                  }
                },
                Time => lambda { |value|
                  {
                    :class => "java.util.Date",
                    :value => {
                      :class => :long,
                      :value => value.to_i * 1000
                    }
                  }
                },
                String => lambda { |value|
                  {
                    :class => :string,
                    :value => value
                  }
                }
    outer = JavabeanXml.to_xml(
              {
                :class => "de.schlichtherle.xml.GenericCertificate",
                :properties => {
                  :encoded => inner,
                  :signature => b64e(sign(inner)),
                  :signatureAlgorithm => "SHA1withDSA",
                  :signatureEncoding => "US-ASCII/Base64"
                }
              },
              String => lambda { |value|
                {
                  :class => :string,
                  :value => value
                }
              }
            )
    encrypt(gzip(outer))
  end


  private

  def gzip data
    gzipped = ""
    zf = Zlib::GzipWriter.new(StringIO.new(gzipped))
    zf << data
    zf.close
    gzipped
  end

  def gunzip data
    Zlib::GzipReader.new(StringIO.new(data)).read
  end

  def sha1 data
    OpenSSL::Digest::SHA1.digest(data)
  end

  def b64e data
    Base64.encode64 data
  end

  def b64d string
    Base64.decode64 string
  end

  def sign data
    @key.syssign sha1(data)
  end

  def verify_signature data, signature
    @key.sysverify(sha1(data), signature)
  end

  def crypt mode, data
    unless @cipher[mode]
      @cipher[mode] = OpenSSL::Cipher.new "DES"
      @cipher[mode].send mode
      @cipher[mode].pkcs5_keyivgen @password, @salt, @iterations
    end
    c = @cipher[mode]
    c.update(data) + c.final
  end

  def decrypt data
    crypt :decrypt, data
  end

  def encrypt data
    crypt :encrypt, data
  end

end

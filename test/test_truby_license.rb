require "rubygems"
require "test/unit"
require "truby_license"
class Fixnum
  def seconds
    self
  end
  def minutes
    60 * seconds
  end
  def hours
    60 * minutes
  end
  def days
    24 * hours
  end
  def weeks
    7 * days
  end
  def months
    30 * days
  end
  def years
    365 * days
  end
  def from_now
    Time.at(Time.now.to_i + self)
  end
  def ago
    Time.at(Time.now.to_i - self)
  end
end
class TestTrubyLicense < Test::Unit::TestCase

  def initialize *args
    super *args
    @key1 = { :priv => OpenSSL::PKey::DSA.generate(1024) }
    @key1[:pub] = @key1[:priv].public_key

    @key2 = { :priv => OpenSSL::PKey::DSA.generate(1024) }
    @key2[:pub] = @key2[:priv].public_key
  end

  def test_serialize_deserialize
    ld = TrubyLicense::LicenseData.new

    ld.consumerType = "0"
    ld.notBefore = 5.days.ago
    ld.notAfter = 10.days.from_now
    ld.extra = "an <html><document /></html>"
    ld.subject = "Some subject"
    ld.holder = "CN=Einar Boson"
    ld.issued = Time.at(Time.now.to_i) # strip ns
    ld.issuer = "CN=Einar Boson"
    tl_priv = TrubyLicense.new "my secret password", @key1[:priv]
    tl_pub = TrubyLicense.new "my secret password", @key1[:pub]

    encoded = tl_priv.serialize_license ld
    decoded = tl_pub.deserialize_license encoded
    ld.each_pair do |prop, val|
      assert_equal val, decoded[prop], "License data should not change through serialization/deserialization"
    end
  end

  def test_exception_on_serializing_with_public_key
    ld = TrubyLicense::LicenseData.new

    ld.consumerType = "0"
    ld.notBefore = 5.days.ago
    ld.notAfter = 10.days.from_now
    ld.extra = "an <html><document /></html>"
    ld.subject = "Some subject"
    ld.holder = "CN=Einar Boson1"
    ld.issued = Time.at(Time.now.to_i) # strip ns
    ld.issuer = "CN=Einar Boson2"

    tl = TrubyLicense.new "my secret password", @key1[:pub]

    assert_raise TrubyLicense::PrivateKeyNeeded do
      tl.serialize_license ld
    end
  end

  def test_license_invalid_if_signed_with_other_key
    ld = TrubyLicense::LicenseData.new

    ld.consumerType = "0"
    ld.notBefore = 5.days.ago
    ld.notAfter = 10.days.from_now
    ld.extra = "an <html><document /></html>"
    ld.subject = "Some subject"
    ld.holder = "CN=Einar Boson"
    ld.issued = Time.at(Time.now.to_i) # strip ns
    ld.issuer = "CN=Einar Boson"
    tl_priv = TrubyLicense.new "my secret password", @key1[:priv]
    t2_pub = TrubyLicense.new "my secret password", @key2[:pub]

    encoded = tl_priv.serialize_license ld

    assert_raise TrubyLicense::InvalidLicense do
      decoded = t2_pub.deserialize_license encoded
    end
  end



  def test_license_invalid_if_wrong_password
    ld = TrubyLicense::LicenseData.new

    ld.consumerType = "0"
    ld.notBefore = 5.days.ago
    ld.notAfter = 10.days.from_now
    ld.extra = "an <html><document /></html>"
    ld.subject = "Some subject"
    ld.holder = "CN=Einar Boson"
    ld.issued = Time.at(Time.now.to_i) # strip ns
    ld.issuer = "CN=Einar Boson"
    tl_priv = TrubyLicense.new "my secret password", @key1[:priv]
    t1_pub = TrubyLicense.new "wrong password", @key1[:pub]

    encoded = tl_priv.serialize_license ld

    assert_raise TrubyLicense::InvalidPassword do
      decoded = t1_pub.deserialize_license encoded
    end
  end
end

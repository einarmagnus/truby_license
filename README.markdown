# Description

This is a library for reading and writing licenses in the same format as [True License] [tl] for java. True License is written by Christian Schlichtherle and is an open source java library for generating and verifying licenses.
My goals and approach were very different to the original library so True License and Truby License will share very little in how they work and are used: I don't know of a way to ship properly obfuscated code in Ruby to allow embedding passwords and keys in an installable, so this is not a way to license programs written in ruby. This is only created to allow me to generate True License files in a Ruby on Rails application, for use in verifying payment for a java-program. Truby License can read license files too, because I wrote that part to figure out how to write them, and I see no reason to throw it out: it is good to be able to inspect and verify a license too.

  [tl]: http://java.net/projects/truelicense "at java.net"

# Use

Because of its intended use being different this library takes a very simplified approach compared to True License.

It has a class `TrubyLicense::LicenseData` which is an instance of `Struct` with the following fields

- `consumerType`, a String
- `notBefore`, a Time
- `notAfter`, a Time
- `extra`, a String
- `subject`, a String
- `holder`, a String  representing a "distinguished name" [see rfc2253](http://www.ietf.org/rfc/rfc2253.txt?number=2253)
- `issued`, a Time
- `issuer`, a String representing a "distinguished name" [see rfc2253](http://www.ietf.org/rfc/rfc2253.txt?number=2253)

These are the fields I use, so those are the ones I have implemented. I think True License has a few more but they were not present in the license files I was generating so they are not here. They should be straightforward to implement should you need to though. Any questions on the code are welcome, just comment on the commit where it was added (you can chose to "blame" a file to find out where a line was committed and comment there).

You instantiate the class `TrubyLicense` with the parameters `password` and `key`, a string and an `OpenSSL::PKey::DSA` respectively:

    require "openssl"

    key = OpenSSL::PKey::DSA.new(open('dsa.pem', "rb", &:read))

    truby_license = TrubyLicense.new "my secret password", key

Then you can create the license data you want:

    ld = TrubyLicense::LicenseData.new
    ld.consumerType = "Computer"
    ld.notBefore = Time.now
    ld.notAfter = 6.months.from_now
    ld.extra = {"custom" => "data"}.to_json
    ld.subject = "Some subject"
    ld.holder = "CN=Valued Customer"
    ld.issued = Time.now
    ld.issuer = "CN=Einar Boson"

and save the license to a file:

    open("license.key", "wb"){ |io| io.write truby_license.serialize_license(ld) }

done.
To read it back, you can do

    ld_dup = truby_license.deserialize_license(open("license.key", "rb", &:read))


That's it. Please be aware that the LicenseData structure does not check the type of its members and that if they are wrong exceptions may be raised, or the format of the license may become invalid. I may add checks at some point, or you can do it if you need it :)

# License

## MIT

Copyright (C) 2011 Einar Magnús Boson

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

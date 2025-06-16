#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2025, by Samuel Williams.

require "async/dns"

describe Resolv::DNS::Message do
	it "should be decoded correctly" do
		data = <<~EOF.unpack1("m")
		HQCBgAABAAgAAAABA3d3dwV5YWhvbwNjb20AAAEAAcAMAAUAAQAAASwADwZm
		ZC1mcDMDd2cxAWLAEMArAAUAAQAAASwACQZkcy1mcDPAMsBGAAUAAQAAADwA
		FQ5kcy1hbnktZnAzLWxmYgN3YTHANsBbAAUAAQAAASwAEg9kcy1hbnktZnAz
		LXJlYWzAasB8AAEAAQAAADwABGKK/B7AfAABAAEAAAA8AARii7SVwHwAAQAB
		AAAAPAAEYou3GMB8AAEAAQAAADwABGKK/W0AACkQAAAAAAAAAA==
		EOF

		message = subject.decode(data)
		expect(message.class).to be == Resolv::DNS::Message
		expect(message.id).to be == 0x1d00

		expect(message.question.size).to be == 1
		expect(message.answer.size).to be == 8
		expect(message.authority.size).to be == 0
		expect(message.additional.size).to be == 1
	end

	it "should fail to decode due to bad AAAA length" do
		data = <<~EOF.unpack1("m")
		6p6BgAABAAEAAAABCGJhaWNhaWNuA2NvbQAAHAABwAwAHAABAAABHgAEMhd7
		dwAAKRAAAAAAAAAA
		EOF

		expect{subject.decode(data)}.to raise_exception(Resolv::DNS::DecodeError)
	end
end

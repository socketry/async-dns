# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2015-2024, by Samuel Williams.

require 'async/dns'

describe Resolv::DNS::Name do
	with 'a relative name' do
		let(:name) {Resolv::DNS::Name.create("foo.bar")}
		
		it "should be relative" do
			expect(name).not.to be(:absolute?)
			expect(name.to_s).to be == "foo.bar"
		end
		
		it "should add the specified origin" do
			fully_qualified_name = name.with_origin("org")
			
			expect(fully_qualified_name.to_a.size).to be == 3
			expect(fully_qualified_name).to be(:absolute?)
			expect(fully_qualified_name.to_s).to be == "foo.bar.org."
		end
		
		it "should handle nil origin as absolute" do
			fully_qualified_name = name.with_origin(nil)
			
			expect(fully_qualified_name.to_a.size).to be == 2
			expect(fully_qualified_name).to be(:absolute?)
			expect(fully_qualified_name.to_s).to be == "foo.bar."
		end
		
		it "should handle empty origin as absolute" do
			fully_qualified_name = name.with_origin('')
			
			expect(fully_qualified_name.to_a.size).to be == 2
			expect(fully_qualified_name).to be(:absolute?)
			expect(fully_qualified_name.to_s).to be == "foo.bar."
		end
	end
	
	with 'an absolute name' do
		let(:name) {Resolv::DNS::Name.create("foo.bar.")}
		
		it "should be absolute" do
			expect(name).to be(:absolute?)
			expect(name.to_s).to be == "foo.bar."
		end
		
		it "should remove the specified origin" do
			relative_name = name.without_origin("bar")
			
			expect(relative_name.to_a.size).to be == 1
			expect(relative_name).not.to be(:absolute?)
			expect(relative_name.to_s).to be == "foo"
		end
		
		it "should not remove nil origin but become relative" do
			relative_name = name.without_origin(nil)
			
			expect(relative_name.to_a.size).to be == 2
			expect(relative_name).not.to be(:absolute?)
			expect(relative_name.to_s).to be == "foo.bar"
		end
		
		it "should not remove empty string origin but become relative" do
			relative_name = name.without_origin('')
			
			expect(relative_name.to_a.size).to be == 2
			expect(relative_name).not.to be(:absolute?)
			expect(relative_name.to_s).to be == "foo.bar"
		end
		
		it "should not raise an exception when origin isn't valid" do
			expect{name.without_origin('bob')}.to raise_exception(Resolv::DNS::OriginError)
		end
	end
end

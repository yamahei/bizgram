require 'spec_helper'
require_relative '../lib/bizgram'

RSpec.describe Bizgram::Validator do
  describe '.validate!' do
    context 'with valid DSL' do
      it 'passes a simple correct DSL' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            user1 = user("User 1")
            bus1 = business("Business 1", :cm)
            user1 -money("Pay")> bus1
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.not_to raise_error
      end

      it 'passes array and integer positions' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            user1 = user("User 1", 0)
            bus1 = business("Business 1", [1, 2])
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.not_to raise_error
      end

      it 'passes comments' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            # This is a comment
            user1 = user("User 1")
            comment_to(user1, "Info", :tl)
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.not_to raise_error
      end
    end

    context 'with malicious or invalid syntax' do
      it 'rejects basic RCE (system call)' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            system("rm -rf /")
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /Unauthorized method call: system/)
      end

      it 'rejects backticks (xstring)' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            `ls`
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /Unauthorized syntax node: xstring/)
      end

      it 'rejects receiver-based method calls (File.read)' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            File.read("secret.txt")
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /Receiver-based method calls are not allowed/)
      end

      it 'rejects string interpolation' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            user("\#{system('ls')}")
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /String interpolation.*is not allowed/)
      end

      it 'rejects reflection attack (send)' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            send(:eval, "puts 'hacked'")
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /Unauthorized method call: send/)
      end

      it 'rejects top-level code outside of Bizgram.draw' do
        dsl = <<~RUBY
          puts "hacked"
          Bizgram.draw("Test") do
            user("A")
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /Top level must be a Bizgram.draw block/)
      end

      it 'rejects missing Bizgram.draw block' do
        dsl = <<~RUBY
          user("A")
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /Top level must be a Bizgram.draw block/)
      end
      
      it 'rejects control flow like loops' do
        dsl = <<~RUBY
          Bizgram.draw("Test") do
            while true do
              user("A")
            end
          end
        RUBY
        expect { Bizgram::Validator.validate!(dsl) }.to raise_error(Bizgram::ValidationError, /Unauthorized syntax node: while/)
      end
    end
  end
end

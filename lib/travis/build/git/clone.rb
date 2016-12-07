require 'shellwords'

module Travis
  module Build
    class Git
      class Clone < Struct.new(:sh, :data)
        def apply
          write_netrc

          sh.fold 'git.checkout' do
            clone_or_fetch
            sh.cd dir
            fetch_ref if fetch_ref?
            checkout
          end
        end

        private

          def clone_or_fetch
            sh.if "! -d #{dir}/.git" do
              sh.cmd "git clone #{clone_args} #{data.source_url} #{dir}", assert: true, retry: true
            end
            sh.else do
              sh.cmd "git -C #{dir} fetch origin", assert: true, retry: true
              sh.cmd "git -C #{dir} reset --hard", assert: true, timing: false
            end
          end

          def fetch_ref
            sh.cmd "git fetch origin +#{data.ref}:", assert: true, retry: true
          end

          def fetch_ref?
            !!data.ref
          end

          def checkout
            sh.cmd "git checkout -qf #{data.pull_request ? 'FETCH_HEAD' : data.commit}", timing: false
          end

          def clone_args
            args = "--depth=#{depth}"
            args << " --branch=#{branch}" unless data.ref
            args << " --quiet" if quiet?
            args
          end

          def depth
            config[:git][:depth].to_s.shellescape
          end

          def branch
            data.branch.shellescape
          end

          def quiet?
            config[:git][:quiet]
          end

          def dir
            data.slug
          end

          def config
            data.config
          end

          def write_netrc
            if data.prefer_https?
              sh.newline
              sh.echo "Using $HOME/.netrc to clone repository.", ansi: :yellow
              sh.newline
              sh.raw "echo -e \"machine github.com\n  login #{data.token}\\n\" > $HOME/.netrc"
              puts "raw_command: echo -e \"machine github.com\n  login #{data.token}\n\" > $HOME/.netrc"
              puts "data.config: #{data.config}"
              puts "data: #{data}"
              sh.raw "chmod 0600 $HOME/.netrc"
            end
          end
      end
    end
  end
end

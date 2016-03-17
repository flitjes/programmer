require 'swd-mchck-bitbang'
require 'swd-buspirate'
require 'cmsis-dap'
begin
  require 'swd-ftdi'
rescue LoadError
  # Not required, we'll just lack support for FTDI
end

module BackendDriver
  class << self
    def create(name, opts)
      case name
      when 'ftdi', 'busblaster'
        Adiv5Swd.new(BitbangSwd.new(FtdiSwd.new(opts)))
      when 'buspirate'
        Adiv5Swd.new(BitbangSwd.new(BusPirateSwd.new(opts)))
      when 'mchck'
        Adiv5Swd.new(BitbangSwd.new(MchckBitbangSwd.new(opts)))
      when 'cmsis-dap'
        Adiv5Swd.new(CmsisDap.new(opts))
      else
        raise RuntimeError, "unknown driver name `#{name}'"
      end
    end

    def from_string_set(a)
      opts = {}
      a.each do |s|
        s.strip!
        name, val = s.split(/[=]/, 2) # emacs falls over with a /=/ regexp :/
        if !val || val.empty?
          raise RuntimeError, "invalid option `#{s}'"
        end
        begin
          val = Integer(val)
        rescue
          # just trying...
        end
        opts[name.to_sym] = val
      end
      name = opts.delete(:name)
      create(name, opts)
    end

    def from_string(s)
      from_string_set(s.split(/:/))
    end

    def options(optparser)
      opts = {}
      optparser.on("--adapter=ADAPTER[,OPTS]", "Use debug adapter ADAPTER, with options OPTS") do |a|
        fields = a.split(/,/)
        opts[:name] = fields[0]
        opts[:opts] = fields[1..-1]
      end
      opts
    end

    def from_opts(opts)
      from_string_set(opts[:opts] + ["name=#{opts[:name]}"])
    end
  end
end

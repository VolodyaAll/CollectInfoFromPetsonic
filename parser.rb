require 'optparse'

class CommandLineParser
  def self.parse(args)
    options = {}
    opts_p = OptionParser.new do |opts|
      init_parser(opts, options)
    end
    raise_error(opts_p, args)

    options
  end

  def self.raise_error(opts_p, args)
    opts_p.parse(args)
  rescue OptionParser::InvalidOption => err
    puts "Exception encountered: #{err} (#{err.class})"
    opts_p.parse %w[--help]
    exit 1
  end

  def self.init_parser(opts, options)
    opt_on_u(opts, options)
    opt_on_f(opts, options)
    opts.on('-h', '--help', 'Prints this help') { puts opts }
  end

  def self.opt_on_u(opts, options)
    opts.on('-uURL', '--url=URL', 'URL to products category like https://www.petsonic.com/snacks-huesos-para-perros/') do |nnn|
      options[:name] = nnn
    end
  end

  def self.opt_on_f(opts, options)
    opts.on('-fFILE', '--file=File.scv', /([a-zA-Z0-9\s_\\.\-\(\):])+.scv$/, '.scv file for results output') do |fff|
      options[:file] = fff[0]
    end
  end
end

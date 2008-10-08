require File.dirname(__FILE__) + '/../lib/lighthouse'
require 'iconv'
require 'erb'

class String
  def to_permalink
    s = Iconv.iconv('ascii//translit//IGNORE', 'utf-8', self.dup.to_s).first.to_s
    s.gsub!('&', ' and ')
    s.gsub!("'", '')
    s.gsub!(/\W+/, ' ') # all non-word chars to spaces
    s.strip!            # ohh la la
    s.downcase!         #
    s.gsub!(/\ +/, '_') # spaces to dashes, preferred separator char everywhere
    s
  end

  def capitalize_first_word
    "#{self.first.upcase}#{self[1..-1]}"
  end
end

class Story
  attr_accessor :number, :role, :subject, :outcome

  def initialize(number, role, subject, outcome)
    @number, @role, @subject, @outcome = number.to_i, role, subject, outcome
  end

  def self.parse(title)
    if %w{so to}.any? {|part| title =~ /#?([0-9\s]* )?As an? (.*) I want (to |a )?(.*) #{part} (.*)/ }
      args = [$1, $2, "#{$3}#{$4}", $5]

      raise 'Error while parsing story.' if args.any?(&:blank?)
      
      new(*args)
    end
  end

  def to_s
    "As #{a_role}\nI want #{subject}\nSo #{outcome}"
  end

  def title
    if subject =~ /(to |a )?(.*)/i
      $2
    else
      subject
    end.capitalize_first_word
  end

  def file_name
    "#{number.to_s.rjust(3, '0')}_#{title.to_permalink}.rb"
  end

  def get_binding
    binding
  end

  private
    def a_role
      %w{a e i o u}.include?(role.first) ? "an #{role}" : "a #{role}"
    end
end

desc "Generate RSpec stories based on Lighthouse tickets."
task :lightspec do
  tickets = Lighthouse::Project.find(5914).tickets(:q => "tagged:story")

  template = ERB.new(File.read(File.dirname(__FILE__) + '/../templates/story.erb'))

  tickets.each do |ticket|
    story = Story.parse("##{ticket.number} #{ticket.title}")

    File.open(File.join(RAILS_ROOT, 'stories', story.file_name), 'w') do |file|
      file.write(template.result(story.get_binding))
    end
    #puts "\x1b\x5b0;32;40m#{subject}: \x1b\x5b1;0;40m#{ticket.title}"
  end
end

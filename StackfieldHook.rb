# frozen_string_literal: true
## StackfieldHook - Chatnachrichten und Aufgaben erstellen in Stackfield-Räumen
# Maic Findeisen Creditreform Hagen Berkey & Riegel KG
# m.findeisen@hagen.creditreform.de
#
# Eine simple Funktion zum Erstellen von Chatnachrichten oder Aufgaben in Stackfield-Räumen
# über die von Stackfield bereitgestellte Webhook-Api.
# Die Klasse kann integriert werden oder das Skript kann selbst über die Shell ausgeführt werden.
# Chatnachrichten sind Type C, Tasks sind Type T
# Aufruf über ruby StackfieldHook -h (--help)
#
# Zur Nutzung müssen die URL für die jeweiligen Bereiche Aufgaben (Task) bzw. Nachricht (Chat)
# im jeweiligen Raum erzeugt und im Skript hinterlegt werden.
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require 'logger'
require 'yaml'
require 'optparse'

# Klasse zur Erzeugung von Eintraegen in Stackfield-Raeumen
class StackfieldHook
  attr_accessor :title, :content, :date_start, :date_end, :users, :log

  def initialize(type="C", title="Titel nicht angegeben", *optional)
    # Configfile laden
    configfile = File.expand_path(File.dirname(__FILE__)) + '/config.yaml'
      unless File.exist?(configfile)
        puts "Die Konfigurationsdatei konnte nicht gefunden werden."
        exit
      else
        @config = YAML::load_file(configfile)
      end

    @log = Logger.new(@config["LOG"]["LOGFILE"], @config["LOG"]["DELETE"])
    @log.datetime_format = "%Y-%m-%d %H:%M"

    case @config["LOG"]["LEVEL"]
      when "debug"
      @log.level = Logger::DEBUG
      when "info"
      @log.level = Logger::INFO
      when "warning"
      @log.level = Logger::WARN
      when "error"
      @log.level = Logger::ERROR
      else
      puts "Fehler in config.yaml -> Falsches oder kein Log-Level."
      exit
    end

    @type = type
    @title = title
    @content = optional[0]
    @date_start = optional[1]
    @users = optional[2]
    @date_end = optional[3]
    @chat_url = @config["STACKFIELD_URL"]["CHAT"]
    @task_url = @config["STACKFIELD_URL"]["TASK"]
  end

  def post
    uri = URI.parse(which_url?)
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"
    request.body = build_payload

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    begin
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          @log.info "Eintrag wird an API übergeben."
          http.request(request)
      end
    rescue => error
      @log.fatal error.message
      exit
    end

    answer = JSON.parse(response.body)
    @log.info "Antwort von Stackfield: (Code #{response.code}) #{answer['Result']} -- #{answer['ErrorText']}"
  end

  def type=(type)
    if /[CT]/.match(type)
      @type = type
    else
      @log.error "Typ muss C (Chat) oder T (Task) sein! Beende Ausführung."
      exit
    end
  end

  def which_url?
    case @type
    when 'C'
      return @chat_url
    when 'T'
      return @task_url
    else
      @log.error "which_url? Eintragstyp konnte nicht erkannt werden."
      exit
    end
  end

  def build_payload
    case @type
      when 'C'
        payload_json = {
        "Title" => @title
        }.to_json
        @log.info "Typ Chatnachricht."
        @log.info "Nachrichtentext: #{@title}"
      when 'T'
        payload_json = {
          "Title" => @title,
          "Content" => @content || '',
          "DateStart" => @date_start || '',
          "DatenEnd" => @date_end || '',
          "Users" => @users
        }.to_json
        @log.info "Typ Task"
        @log.info "Titel der Aufgabe: #{@title}"
      else
        @log.error "Eintragstyp konnte nicht erkannt werden."
    end
    @log.debug payload_json.to_s
    return payload_json
  end

end


# Aufruf von StackfieldHook (Kommandozeilentool)

if __FILE__ == $0

  options = {:type => nil, :title => nil}

  parser = OptionParser.new do|opts|
    opts.banner = "Usage: StackfieldHook.rb [options]"
    opts.on('-t', '--type type', 'Eintragstyp. C = Chatnachricht / T = Task/Aufgabe') do |type|
      options[:type] = type;
    end

    opts.on('-m', '--message Titeltext', 'Chatnachricht oder Titel der Aufgabe') do |message|
      options[:message] = message;
    end

    opts.on('-c', '--content Aufgabenbeschreibung', 'Beschreibungstext der Aufgabe.') do |content|
      options[:content] = content;
    end

    opts.on('-s', '--startdate YYYY-MM-DD', 'Aufgabendatum Fälligkeit. (Bei Angabe von Enddatum das Startdatum)') do |date_start|
      options[:date_start] = date_start;
    end

    opts.on('-u', '--users user@stackfield.de', 'E-Mail des für die Aufgabe zuständigen Stackfield-Nutzers') do |users|
      options[:users] = users;
    end

    opts.on('-e', '--enddate YYYY-MM-DD', 'Aufgaben-Enddatum bei von-bis Aufgaben.') do |date_end|
      options[:date_end] = date_end;
    end

    opts.on('-h', '--help', 'Hilfe anzeigen') do
      puts opts
      exit
    end
  end

  parser.parse!

  if options[:type] == nil
    print 'Typ wird benötigt (C=Chatnachricht/T=Task): '
      options[:type] = gets.chomp
  end

  if !/[CT]/.match(options[:type])
    until /[CT]/.match(options[:type]) do
      print 'Typ muss C oder T (C=Chatnachricht oder T=Task) sein: '
      options[:type] = gets.chomp
    end
  end

  if options[:message] == nil
    print 'Der Inhalt der Nachricht / Titel der Aufgabe wird benötigt: '
      options[:message] = gets.chomp
  end

  webhook = StackfieldHook.new(options[:type], options[:message], options[:content], options[:date_start], options[:users], options[:date_end])

  # Log umbiegen auf STDOUT wenn Aufruf über Kommandozeile
  webhook.log = Logger.new(STDOUT)
  webhook.log.level = Logger::INFO
  webhook.post

end
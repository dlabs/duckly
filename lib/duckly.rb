# coding: utf-8
require "bundler/setup"
require "duckly/version"
require "httparty"
require "nokogiri"
require "oj"
require "json"

class Duckly
  include HTTParty
  no_follow true
  base_uri "https://duck.dlabs.si/"
  format :html

  attr_accessor :cookie

  def initialize params={}
    @params = params
    authenticate(params) if params != {}
  end

  def authenticate params={}
    params = @params if params == {}
    cookie = nil
    begin
      self.class.post "/auth/login", query: {
        uid: params[:email] || params[:uid],
        pwd: params[:password] || params[:pwd]
      }
    rescue HTTParty::RedirectionTooDeep => e
      cookie = e.response.get_fields('Set-Cookie')[1].match(/\w{32}+/).to_s rescue nil
    end

    raise Duckly::SecurityError, "Wrong credentials" if cookie.nil?

    @cookie = cookie
    self.class.cookies({'DuckSID' => @cookie})
    @cookie
  end

  def authenticated?
    @is_authenticated ||= true unless @cookie.nil?
  end

  class SecurityError < StandardError; end

  def me
    self.class.no_follow false
    response = self.class.get "/me"

    doc = Nokogiri::HTML(response)

    basic = doc.xpath("//div[@class='basic']//td").map(&:content)
    basic = basic.select.with_index{|_,i| (i+1) % 2 != 0 }.zip(basic.select.with_index{|_,i| (i+1) % 2 == 0 })
    a = Hash[basic.collect {|k,v| [k.force_encoding("UTF-8"), v.strip.force_encoding("UTF-8")]}]

    contact = doc.xpath("//div[@class='contact']//td").map(&:content)
    contact = contact.select.with_index{|_,i| (i+1) % 2 != 0 }.zip(contact.select.with_index{|_,i| (i+1) % 2 == 0 })
    b = Hash[contact.collect {|k,v| [k.force_encoding("UTF-8"), v.strip.force_encoding("UTF-8")]}]

    a.merge! b
  end

  def tickets query
    self.class.no_follow true

    params = { body: { jsonrpc: "2.0", method: "tickets.find", params: [query], id: 999 }.to_json }

    response = self.class.post "/api/", params

    tickets = Oj.load(response.body)["result"] rescue []

    tickets.map {|t| Ticket.new(t) }
  end

  # d.add_hours "jira://local/Utelier/ticket/12865/UT-215", "30", "2013-07-05", "Hacking"
  def add_hours ticket_url, worktime, date, comment
    self.class.no_follow true

    params = { body: { action: 'saveActivity',
      ticketUri:       ticket_url,
      time:            worktime,
      started:         date,
      comment:         comment.strip,
      publishComment:  0
    } }

    response = self.class.post("/activities/submit", params)
    response.body.strip == ""
  end

  def my_flow offset=0
    self.class.no_follow true

    response = self.class.get "/activities/my-flow", {
      headers: { "X-Requested-With" => "XMLHttpRequest" },
      query: { paging_offset: offset }
    }

    doc = Nokogiri::HTML(response)

    infos = doc.xpath("//div[@class='info']").map do |div_info|
      {
        "ticket-name" => div_info.xpath("//div[@class='info']").first.xpath("span[@class='ticket']/a").first.content.strip,
        "project-name" => div_info.xpath("//div[@class='info']").first.xpath("span[@class='project']/a").first.content.strip,
        "time-worked" => div_info.xpath("span[@class='time-worked']").first.content.strip,
        "project-url" => div_info.xpath("//div[@class='info']").first.xpath("span[@class='project']/a").first["href"],
        "ticket-uri" => div_info.xpath("//div[@class='info']").first.xpath("span[@class='ticket']/a").first["ref"],
        "ticket-url" => div_info.xpath("//div[@class='info']").first.xpath("span[@class='ticket']/a").first["href"],
        "activity-date" => div_info.xpath("//div[@class='info']").first.xpath("span[@class='activity-date']").first.content.strip
      }
    end

    infos.map { |a| FlowActivity.new(a) }
  end

end

class Duckly
  class Ticket < OpenStruct; end
  class FlowActivity < OpenStruct; end
end

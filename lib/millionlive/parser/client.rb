require 'mechanize'

module Millionlive::Parser
  class Client
  LOGIN = 'https://id.gree.net/login/entry'
  RANKING_PER_PAGE = 10

    def initialize email, passwd
      # agent setting
      @agent = Mechanize.new
      @agent.user_agent_alias = 'iPhone'
      @agent.redirect_ok = 'true'
      @agent.redirection_limit = 3

      # login
      @agent.get LOGIN
      @agent.page.form.field('mail').value = email
      @agent.page.form.field('user_password').value = passwd
      @agent.page.form.submit
    end

    # get event ranking
    def event_ranking(event_id, upto=2000, idol_no=nil)
      (1..Float::INFINITY).each.lazy.flat_map do |index|
        url = "http://imas.gree-apps.net/app/index.php/event/#{event_id}/ranking/general?page=#{index}&idol=#{idol_no}"
        if index == 1
          visit url
        else
          @agent.get url
        end

        css = '#wrapper td.user-list-st'
        tds = page.search(css)
        tds.map do |td|
          {
            rank: td.children[0].text.to_i,
            name: td.children[3].text,
            point: td.children[7].text.delete(',').to_i,
          }
        end
      end.take_while{|h| h[:rank] <= upto}.to_a
    end

    # visit a specified url(submit is needed after agent.get)
    def visit url
      @agent.get url
      @agent.page.form&.submit
    end

    def body
      @agent.page.body
    end

    def page
      @agent.page
    end

  end
end

require 'mechanize'

module Millionlive::Parser
  class Client
  LOGIN = 'https://id.gree.net/login/entry'
  RANKING_PER_PAGE = 10
  RANKING_URL = "http://imas.gree-apps.net/app/index.php/event/%s/ranking/general?page=%s&idol=%s"

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

    def event_ranking_pages(event_id, page_nos, idol_no=nil)
      # ランキングページを一度visitしておかないとあとの処理ができない
      visit format(RANKING_URL, event_id, 1, idol_no)
      page_nos.flat_map do |page_no|
        event_ranking_page(event_id, page_no, idol_no)
      end
    end

    def event_ranking_page(event_id, page_no, idol_no=nil)
      @agent.get format(RANKING_URL, event_id, page_no, idol_no)
      css = '#wrapper td.user-list-st'
      tds = page.search(css)
      tds.map do |td|
        {
          rank: td.children[0].text.to_i,
          name: td.children[3].text,
          user_id: td.children[3].attr('href').split('/').last.to_i,
          point: td.children[7].text.delete(',').to_i,
        }
      end
    end

    def ula_ranking(event_id, upto, team_no)
      (1..Float::INFINITY).each.lazy.flat_map do |index|
        url = "http://imas.gree-apps.net/app/index.php/event/#{event_id}/ranking/ula?page=#{index}&team=#{team_no}"
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
            user_id: td.children[3].attr('href').split('/').last.to_i,
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

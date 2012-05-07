require 'spec_helper'

describe "Navigation" do
  include Capybara::DSL

  it "renders the stopwatch box" do
    visit "/"
    page.should have_css("#performance_code")
  end

  it "does not insert html" do
    visit "/javascript_test"
    page.should_not have_css("#performance_code")
  end

  it "does not mix concurrent requests" do
    Item.delete_all
    # spurious show keys etc
    visit "/access_db?name=0"
    max=10
    threads = (1..max).map do |i|
      Thread.new do |x|  
        sleep rand
        visit "/access_db?name=#{i}"
        Stopwatch.current_log.query_count.should == 1 
        page.should_not have_css("#performance_code")
      end
    end
    threads.each {|t| t.join}
    names = Item.all.map(&:name)
    names.size.should == max +1
    names.should_not == (0..max).map(&:to_s)
  end
end

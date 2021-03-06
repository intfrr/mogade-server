require 'spec_helper'

describe Api::RanksController, :index do
  extend ApiHelper
  
  setup
  it_ensures_a_valid_version :get, :index
  it_ensures_a_valid_player :get, :index
  it_ensures_a_valid_leaderboard :get, :index, Proc.new { {:username => 'paul', :userkey => 'fail'} }
  
  it "gets the ranks" do
    leaderboard = Factory.create(:leaderboard)
    player = Factory.build(:player)
    Rank.should_receive(:get).with(leaderboard, player.unique)
    get :index, ApiHelper.versioned({:lid => leaderboard.id, :username => player.username, :userkey => player.userkey})
  end
  
  it "returns the ranks" do
    leaderboard = Factory.create(:leaderboard)
    player = Factory.build(:player)
    ranks = {:daily => 44, :weekly => 3}
    
    Rank.stub!(:get).and_return(ranks)
    get :index, ApiHelper.versioned({:lid => leaderboard.id, :username => player.username, :userkey => player.userkey});
    
    response.status.should == 200
    json = ActiveSupport::JSON.decode(response.body)
    json['daily'].should == 44
    json['weekly'].should == 3
  end
  
  it "returns the ranks within the specific callback" do
    leaderboard = Factory.create(:leaderboard)
    player = Factory.build(:player)
    ranks = {:daily => 44, :weekly => 3}
    
    Rank.stub!(:get).and_return(ranks)
    get :index, ApiHelper.versioned({:lid => leaderboard.id, :username => player.username, :userkey => player.userkey, :callback => 'gotRanks'})
    
    response.status.should == 200
    response.body.should == 'gotRanks({"daily":44,"weekly":3});'
  end
  
  it "sets output cache set when callback is used" do
    leaderboard = Factory.create(:leaderboard)
    player = Factory.build(:player)
    
    Rank.stub!(:get).and_return({})
    get :index, ApiHelper.versioned({:lid => leaderboard.id, :username => player.username, :userkey => player.userkey, :callback => 'gotScores'})
    
    response.headers['Cache-Control'].should == 'public, max-age=300'
  end
  
  it "does not set output cache when callback is not used" do
    leaderboard = Factory.create(:leaderboard)
    player = Factory.build(:player)
    
    Rank.stub!(:get).and_return({})
    get :index, ApiHelper.versioned({:lid => leaderboard.id, :username => player.username, :userkey => player.userkey})
    
    response.headers['Cache-Control'].should == 'max-age=0, private, must-revalidate'
  end
end
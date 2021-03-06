require 'spec_helper'
require 'controllers/authentication_helper'

describe Admin::ConfigurationsController do
  
  before(:each) do
    sign_on
  end
  
  describe "GET 'edit'" do
    it "should load the current configuration" do
      configuration = Configuration.new
      Configuration.should_receive(:instance).and_return(configuration)
      get 'edit'      
      response.should be_success
      assigns[:configuration].should == configuration
    end
  end

  describe "PUT 'update'" do
    it "should get the current instance and update the values" do
      configuration = Configuration.new
      params = {:configuration => {}}
      configuration.should_receive(:update_attributes).with(params[:configuration]).and_return(true)
      Configuration.should_receive(:instance).and_return(configuration)
      put 'update', :id => 1, :configuration => params[:configuration]      
      response.should redirect_to root_path
      assigns[:configuration].should == configuration
      flash[:notice].should == 'Successfully updated the configuration changes'
    end
  end
  
  describe "POST 'create'" do
    it "should create a new instance" do
      configuration = Configuration.new
      params = {:configuration => {}}
      configuration.should_receive(:save).and_return(true)
      Configuration.should_receive(:new).with(params[:configuration]).and_return(configuration)
      post 'create', :configuration => params[:configuration]      
      response.should redirect_to root_path
      assigns[:configuration].should == configuration
      flash[:notice].should == 'Successfully created the configuration changes'
    end
  end

  describe "POST send_sms" do
    it("should send sms using Moonshado") do
      mock_sms = ""
      Moonshado::Sms.should_receive(:new).with("1-555-5556471","Test sms").and_return(mock_sms)
      mock_sms.should_receive(:deliver_sms)
      post 'send_sms' , :number => "1-555-5556471", :message => "Test sms"
      flash[:notice].should == 'Successfully sent the sms'
      response.should redirect_to(edit_admin_configuration_path)
    end

    it("should fail to send the message when message length ") do
      post 'send_sms' , :number => "1-555-5556471", :message => "The length of this message is more than 163 characters and so this should easily fail. Lets try it out.Adding another line to increase te count. The number of characters is increasing now"
      flash[:error].should == 'Error sending SMS: Invalid message '
      response.should redirect_to(edit_admin_configuration_path)
    end

    it("should fail to send the message when using invalid ") do
      post 'send_sms' , :number => "invalid number", :message => "Test"
      flash[:error].should == 'Error sending SMS: Phone number (invalid number) is not formatted correctly '
      response.should redirect_to(edit_admin_configuration_path)
    end
  end


  describe "GET testEpiConnection" do
    it("should fail epi connection check") do
      HTTParty.should_receive(:post).and_return({"error" => "some error message"})
      get 'testEpiConnection', :epiURL => "https://www.episurveyor.org", :epiUser => "test@gmail.com", :epiToken => "dummyToken"

      @expected = {
          :status  => "NOT OK",
      }.to_json
      response.body.should == @expected
    end

    it("should fail epi connection check on exception") do
      HTTParty.should_receive(:post).and_raise ("Some connection exception")
      get 'testEpiConnection', :epiURL => "https://www.episurveyor.org", :epiUser => "test@gmail.com", :epiToken => "dummyToken"

      @expected = {
          :status  => "NOT OK",
      }.to_json
      response.body.should == @expected
    end


    it("should pass epi connection check") do
      HTTParty.should_receive(:post).and_return({"no-error" => "All is well. No error"})
      get 'testEpiConnection', :epiURL => "https://www.episurveyor.org", :epiUser => "test@gmail.com", :epiToken => "dummyToken"

      @expected = {
          :status  => "OK",
      }.to_json
      response.body.should == @expected
    end

  end

  describe "GET testSFConnection" do
    it("should fail salesforce connection check") do

      sfURL = "https://test.salesforce.com/services/Soap/u/20.0"
      sfUser = "test@gmail.com"
      sfToken = "dummyToken"

      mock_binding = ""
      RForce::Binding.should_receive(:new).and_return(mock_binding)
      mock_binding.should_receive(:login).with(sfUser, sfToken).and_raise("Login failed exception")

      get 'testSFConnection', :sfURL => sfURL, :sfUser => sfUser,:sfToken => sfToken

      @expected = {
          :status  => "NOT OK",
      }.to_json
      response.body.should == @expected
    end

    it("should pass salesforce connection check") do

      sfURL = "https://test.salesforce.com/services/Soap/u/20.0"
      sfUser = "test@gmail.com"
      sfToken = "dummyToken"

      mock_binding = ""
      RForce::Binding.should_receive(:new).and_return(mock_binding)
      mock_binding.should_receive(:login).with(sfUser, sfToken)

      get 'testSFConnection', :sfURL => sfURL, :sfUser => sfUser,:sfToken => sfToken

      @expected = {
          :status  => "OK",
      }.to_json
      response.body.should == @expected
    end

  end

  after(:each) do
    Configuration.rspec_reset
  end
  
  
  
end
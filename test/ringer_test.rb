require 'test_helper'
require 'ringer'

class RingerTest < ActiveSupport::TestCase
  def setup
    @user = "apitest"
    @password = "Innio"
    @partner_id = 0

    begin
      @r = Ringer::Wyless.new(@user, @password, @partner_id)
    rescue
      @r = Ringer::Wyless.new(@user, @password, @partner_id, false)
    end

    @data = {'SIMNo' => 8901260761228952977}
  end

  test "auto auth" do
    assert_nothing_raised do
      r = Ringer::Wyless.new(@user, @password, @partner_id)
    end
  end

  test "auth fail" do
    r = Ringer::Wyless.new(@user, @password, 123)
    assert !r.authenticate
  end

  test "auth success" do
    r = Ringer::Wyless.new(@user, @password, @partner_id, false)
    assert r.authenticate
  end

  test "single sim inquiry" do
    result = @r.single_sim_inquiry(@data)
    assert_equal result[:result], "Success"

    result = @r.single_sim_inquiry({})
    assert_equal result[:result], "Failed"
  end

  test "ping" do
    sim = @r.single_sim_inquiry(@data)

    result = @r.single_sim_inquiry({'SIMNo' => sim[:sim_no], 'IP'=> sim[:ip_address], 'MSISDN' => sim[:msisdn]})
    assert result.include?("Pinging")
  end

  test "restore and suspend" do
    2.times do
      result = @r.single_sim_inquiry(@data)
      if result[:status] == "Suspended"
        result = @r.single_restore_sim(@data)
        assert_equal "Success", result[:result], result
        assert_equal "Active", result[:status], result
      else
        result = @r.single_suspend_sim(@data) 
        assert_equal "Success", result[:result], result
        assert_equal "Suspended", result[:status], result
      end
      sleep(60)
    end
  end
end

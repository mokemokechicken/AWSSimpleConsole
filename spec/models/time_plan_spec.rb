require 'spec_helper'
require 'time_plan'

describe TimePlan do
  before do
    @obj = create_obj
  end

  def create_obj
    TimePlan.new
  end

  it '10-19 inlucde Fri,13H' do
    @obj.parse('10-19')
    @obj.include?(5, 13).should be_true
  end

  it '10-19 donot inlucde Fri,3H' do
    @obj.parse('10-19')
    @obj.include?(5, 3).should be_false
  end

  it '19-5 inlucde Fri,22 and Fri 3' do
    @obj.parse('19-5')
    @obj.include?(5, 22).should be_true
    @obj.include?(5, 3).should  be_true
  end

  it '19-5 donot inlucde Fri,10' do
    @obj.parse('19-5')
    @obj.include?(5, 10).should be_false
  end

  it '6 inlucde Fri,6' do
    @obj.parse('6')
    @obj.include?(5, 6).should be_true
  end

  it '6 donot inlucde Fri,9' do
    @obj.parse('6')
    @obj.include?(5, 9).should be_false
  end

  it '5,6,9 inlucde Fri,6' do
    @obj.parse('5,6,9')
    @obj.include?(5, 6).should be_true
  end

  it '5,6,9 to 12 inlucde Fri,11' do
    @obj.parse('5,6,9 to 12')
    @obj.include?(5, 11).should be_true
  end

  it '5,6,9 donot inlucde Fri,7' do
    @obj.parse('5,6,9')
    @obj.include?(5, 7).should be_false
  end

  it '水 inlucde Wed,ALL' do
    @obj.parse('水')
    @obj.include?(3, 0).should be_true
    @obj.include?(3, 13).should be_true
    @obj.include?(3, 23).should be_true
  end

  it '水 donot inlucde Thu,ALL' do
    @obj.parse('水')
    @obj.include?(4, 0).should be_false
    @obj.include?(4, 13).should be_false
    @obj.include?(4, 23).should be_false
  end

  it '月〜金,月-金,月ー金,月to金 inlucde Thu,*' do
    obj = create_obj
    obj.parse('月〜金')
    obj.include?(4, 13).should be_true

    obj = create_obj
    obj.parse('月-金')
    obj.include?(4, 13).should be_true

    obj = create_obj
    obj.parse('月ー金')
    obj.include?(4, 13).should be_true

    obj = create_obj
    obj.parse('月to金')
    obj.include?(4, 13).should be_true
  end

  it '月〜金,月-金,月ー金,月 to 金 donnot inlucde Sun,*' do
    obj = create_obj
    obj.parse('月〜金')
    obj.include?(0, 13).should be_false

    obj = create_obj
    obj.parse('月-金')
    obj.include?(0, 13).should be_false

    obj = create_obj
    obj.parse('月ー金')
    obj.include?(0, 13).should be_false

    obj = create_obj
    obj.parse('月 to 金')
    obj.include?(0, 13).should be_false
  end

  it '月〜金 && 10-19 inlucde Thu,14' do
    @obj.parse('月〜金 && 10-19')
    @obj.include?(4, 14).should be_true
  end

  it '月〜金 && 10-19 donot inlucde Sat,14' do
    @obj.parse('月〜金 && 10 to 19')
    @obj.include?(6, 14).should be_false
  end

  it '金〜火 && 10,11,12-19 inlucde Sun,14' do
    @obj.parse('金 to 火 && 10,11,12-19')
    @obj.include?(0, 14).should be_true
    @obj.include?(0, 11).should be_true
  end

  it '金〜火 && 10-19 donot inlucde Wed,14' do
    @obj.parse('金〜火 && 10-19')
    @obj.include?(3, 14).should be_false
  end

  it '金〜火 && 10-19 donot inlucde Sun,23' do
    @obj.parse('金〜火 && 10-19')
    @obj.include?(0, 23).should be_false
  end
end
class TimePlan
  RANGE_STR = %w(- ー 〜 to TO To)
  ENUM_STR  = %w(,)
  AND_STR   = %w(&&)

  def initialize
    @conditions = []
  end

  def self.parse(plan)
    new.parse(plan)
  end

  def parse(plan)
    parse_and(plan)
    self
  end

  def include?(wday, hour)
    @conditions.each do |cond_obj|
      unless cond_obj.check({:wday => wday, :hour => hour})
        return false
      end
    end
    true
  end

  def parse_and(plan)
    conditions = split_by_any(plan.strip.gsub(' ', ''), AND_STR)
    conditions.each do |cond|
      store_condition(cond)
    end
  end

  def split_by_any(s, sep_array)
    s.split(/#{sep_array.map{|s| Regexp.escape(s)}.join('|')}/)
  end

  def store_condition(cond)
    cond_any_list = split_by_any(cond, ENUM_STR)
    conds = []
    cond_any_list.each do |cond_any|
      range = split_by_any(cond_any, RANGE_STR)
      if range.size == 1
        conds << Condition.create(range[0])
      else
        from_to(range[0], range[1]) do |t|
          conds << t
        end
      end
    end
    @conditions << AnyCondition.new(conds)
  end

  def from_to(from, to)
    from_obj = Condition.create(from)
    to_obj = Condition.create(to)
    from_obj.upto(to_obj) do |t|
      yield t
    end
  end
end

WDAYS_KANJI = %w(日 月 火 水 木 金 土)

class Condition
  def self.create(s)
    if s =~ /^[0-9]+$/
      HourConditioin.create(s.to_i)
    elsif WDAYS_KANJI.include?(s)
      WdayCondition.create(s)
    end
  end
end

class HourConditioin < Condition
  attr_reader :hour

  def self.create(hour)
    new(hour)
  end

  def inspect
    "Hour:#{@hour}"
  end

  def initialize(hour)
    @hour = hour.to_i
    raise ArgumentError.new("hour must be 0 <= hour <= 23, but #{hour}") if @hour < 0 or 23 < @hour
  end

  def upto(to_obj)
    raise ArgumentError.new unless to_obj.kind_of?(HourConditioin)
    if @hour <= to_obj.hour
      @hour.upto(to_obj.hour) do |t|
        yield HourConditioin.create(t)
      end
    else
      @hour.upto(23) do |t|
        yield HourConditioin.create(t)
      end
      0.upto(to_obj.hour) do |t|
        yield HourConditioin.create(t)
      end
    end
  end

  def check(target)
    target[:hour] == @hour
  end
end

class WdayCondition < Condition
  attr_reader :wday
  def self.create(wday_str)
    new(wday_str)
  end

  def inspect
    "wday:#{WDAYS_KANJI[@wday]}"
  end

  def initialize(wday_str, wday=nil)
    unless wday || WDAYS_KANJI.include?(wday_str)
      raise ArgumentError.new("#{wday_str} is not wday expression")
    end
    @wday = wday ? wday.to_i : WDAYS_KANJI.index(wday_str)
  end

  def upto(to_obj)
    raise ArgumentError.new unless to_obj.kind_of?(WdayCondition)
    if @wday <= to_obj.wday
      @wday.upto(to_obj.wday) do |t|
        yield WdayCondition.new(nil, wday=t)
      end
    else
      @wday.upto(6) do |t|
        yield WdayCondition.new(nil, wday=t)
      end
      0.upto(to_obj.wday) do |t|
        yield WdayCondition.new(nil, wday=t)
      end
    end
  end

  def check(target)
    if WDAYS_KANJI.include?(target[:wday])
      WDAYS_KANJI.index(target[:wday]) == @wday
    else
      target[:wday] == @wday
    end
  end
end

class AnyCondition
  def initialize(conds)
    @conditions = conds
  end

  def check(target)
    @conditions.each do |cond_obj|  # Hour, Wday Condition
      if cond_obj.check(target)
        return true
      end
    end
    false
  end
end
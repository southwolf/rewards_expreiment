# encoding: utf-8

require 'csv'
require 'timeout'

Shoes.app width: 600, height: 500, title: "行为实验箱" do

  @trials = 1
  @prob_rewards = [100.0, 1000.0, 50000.0]
  @prob_reward = @prob_rewards[0]
  @probs = [0.95, 0.90, 0.75, 0.55, 0.30, 0.10, 0.05].reverse!
  @prob = @probs[0]

  @instant_reward = @prob_reward / 2
  @previous_instant_reward = @instant_reward
  @instant_reward_delta = @prob_reward - @instant_reward

  @numbers = (1..9).to_a.sample(5)

  @reward_count = 0
  @result = 0
  @correct_input = 0.0

  background white
  background tan, height: 60
  banner strong("概率折扣实验"), align: "center", stroke: white, size:30, margin_top: 10
  @subject = ask("您的编号?")
  @file_name = "prob_#{@subject}.csv"
  @key_log = "prob_keys_#{@subject}.log"

  File.open(@file_name,'wb') do |f|
    header = 'EF BB BF'.split(' ').map{|a|a.hex.chr}.join()
    f.write header
  end

  CSV.open(@file_name,'a',encoding:'UTF-8') do |csv|
    csv <<['试次', '赔率', '概率奖赏', '结果', '同时作业', '正确率']
  end

  keypress do |key|
    File.open(@key_log, 'a') { |f| f << key.inspect }
    if key.inspect == @number
      @correct_input += 1.0
    end
    do_test
  end

  @splash = stack margin_top: 50 do
    subtitle "请按照屏幕提示，根据自己的真实感受作出选择", align: "center", font: "SimSun"

    button("确定", size: 24, margin_left: 260, margin_top: 80) { begin_test }
  end

  def clear_screen
    @splash.clear unless @splash.nil?
    @next_prob_screen.clear unless @next_prob_screen.nil?
    @next_reward_screen.clear unless @next_reward_screen.nil?
    @test.clear unless @test.nil?
    @number_show.clear unless @number_show.nil?
    @number_input.clear unless @number_input.nil?
  end

  def begin_test
    clear_screen
    if @reward_count == 0 # 每一个 block
      @numbers = (1..9).to_a.sample(5)
      @number_show = flow do
        subtitle "请记住以下五位数\n每次测试将要求您用键盘\n输入其中一个数字\n", align: "center"
        subtitle "#{@numbers.join}", align: "center", stroke: red
        timer 5 do
          @number_show.clear
          do_test
        end
      end
    else
      do_test
    end
  end

  def do_test

    clear_screen

    @test = flow do
      left = stack width: 300 do
        subtitle "100% \n获得 #{@instant_reward.round(2)} 元"
        button("选择", size: 60) { less_instant_reward }
      end
      right = stack width: 300 do
        subtitle "#{(@prob * 100).to_i}% 可能\n获得 #{@prob_reward.round(2)} 元"
        button("选择", size: 80) { more_instant_reward }
      end
    end
  end

  def do_cocurrent_activity
    clear_screen

    @number_input = flow do
      @number = @numbers.sample
      subtitle "请用键盘输入第#{@numbers.find_index(@number) + 1}位数字", align: "center"
    end
  end

  def next_test

    CSV.open(@file_name,'a',encoding:'UTF-8') do |csv|
      csv<<[@trials, (1 - @prob) / @prob, @prob_reward, @result, @numbers.join, @correct_input / @reward_count]
    end
    
    clear_screen

    if @trials == @probs.length * @prob_rewards.length
      @exit_screen = stack do
        subtitle "实验完成！\n感谢您的配合。再见！", align: "center"
      end
    else
      if @trials > 0 && @trials % @probs.length == 0

        csv = CSV.open(@file_name,'a',encoding:'UTF-8')
        csv<<['', '', '', '', '', '']  # 插入空行
        csv.close

        @next_reward_screen = stack do
          subtitle "请进行下一次选择，注意：奖赏会发生变化", align: "center"
          button("确定", size: 24, margin_left: 260, margin_top: 80) { begin_next_reward }
        end

      else
        @next_prob_screen = stack do
          subtitle "请进行下一次选择，注意：概率将发生变化", align: "center"
          button("确定", size: 24, margin_left: 260, margin_top: 80) { begin_next_prob }
        end
      end
    end
  end

  def begin_next_reward
    index = @prob_rewards.find_index(@prob_reward)
    @prob_reward = @prob_rewards[index + 1]
    @instant_reward = @prob_reward / 2
    @previous_instant_reward = @instant_reward
    @instant_reward_delta = @prob_reward - @instant_reward
    @reward_count = 0
    @prob = @probs[0]
    @trials += 1
    begin_test
  end

  def begin_next_prob
    index = @probs.find_index(@prob)
    @prob = @probs[index + 1]
    @instant_reward = @prob_reward / 2
    @previous_instant_reward = @instant_reward
    @instant_reward_delta = @prob_reward - @instant_reward
    @reward_count = 0
    @trials += 1
    begin_test
  end

  def less_instant_reward
    if @reward_count == 6
      @result = @instant_reward - @instant_reward_delta / 2
      next_test
    else
      @previous_instant_reward = @instant_reward
      @instant_reward = @previous_instant_reward - @instant_reward_delta / 2
      @instant_reward_delta = @previous_instant_reward - @instant_reward
      @reward_count += 1
      do_cocurrent_activity
    end
  end

  def more_instant_reward
    if @reward_count == 6
      @result = @instant_reward + @instant_reward_delta / 2
      next_test
    else
      @previous_instant_reward = @instant_reward
      @instant_reward = @previous_instant_reward + @instant_reward_delta / 2
      @instant_reward_delta = @instant_reward - @previous_instant_reward
      @reward_count += 1
      do_cocurrent_activity
    end
  end
end


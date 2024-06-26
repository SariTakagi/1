require 'dxruby'

# ウィンドウの設定
Window.width = 1200
Window.height = 1000

# Cannonballクラス
class Cannonball < Sprite
  attr_reader :fired

  def initialize(x, y)
    @image = Image.load('assets/images/cannonball.png')  # 砲弾の画像を読み込む
    super(x+100, y, @image)
    @velocity = 0
    @fired = false
  end

  def fire
    @velocity = -5  # 砲弾の速度を設定
    @fired = true
  end

  def update
    if @fired
      self.y += @velocity  # 砲弾が発射されたら位置を更新
      vanish if self.y < 0  # 画面外に出たら消滅
    end
  end

  def out_of_bounds
    self.y < 0
  end
end

# Blockクラス
class Block < Sprite
  def initialize(x, y)
    @image = Image.load('assets/images/blok.jpg')  # ブロックの画像を読み込む
    super(x, y, @image)
  end
end

# Gameクラス
class Game
  attr_reader :game_over, :misses, :target_filename, :score, :game_clear

  def initialize
    @background = Image.load('assets/images/background.png')  # 背景画像を読み込む
    @start_background = Image.load('assets/images/OIP.jpg')  # スタート画面の背景画像を読み込む
    @blocks = []
    10.times do |i|
      8.times do |j|
        @blocks << Block.new(100 + i * 100, 50 + j * 100)  # ブロックを10x10に配置
      end
    end
    @cannonballs = []
    @cannon_x = Window.width / 2
    @cannon_y = Window.height - 200  # 大砲の位置を画面下部に設定
    @font = Font.new(24, 'メイリオ', weight: true)  # メイリオフォントを使用
    @score = 0
    @misses = 0
    @input_mode = false
    @shot_mode = false
    @game_over = false
    @game_clear = false
    @input_text = ""

    # 発射位置に表示する砲台の画像
    @cannon_image = Image.load('assets/images/cannon.png')

    # ランダムなターゲット画像を選択
    target_images = Dir.glob('assets/images/target*.png')  # target*.png にマッチするファイルを取得
    @target_filename = File.basename(target_images.sample, ".*")  # ファイル名を拡張子なしで取得
    @target = Image.load("assets/images/#{@target_filename}.png")  # ターゲット画像を読み込む

    # キーコードと文字の対応をハッシュで定義
    @key_to_char = {
      K_A => 'a', K_B => 'b', K_C => 'c', K_D => 'd', K_E => 'e',
      K_F => 'f', K_G => 'g', K_H => 'h', K_I => 'i', K_J => 'j',
      K_K => 'k', K_L => 'l', K_M => 'm', K_N => 'n', K_O => 'o',
      K_P => 'p', K_Q => 'q', K_R => 'r', K_S => 's', K_T => 't',
      K_U => 'u', K_V => 'v', K_W => 'w', K_X => 'x', K_Y => 'y', K_Z => 'z',
      K_0 => '0', K_1 => '1', K_2 => '2', K_3 => '3', K_4 => '4',
      K_5 => '5', K_6 => '6', K_7 => '7', K_8 => '8', K_9 => '9',
      K_SPACE => ' ', K_COMMA => ',', K_PERIOD => '.', K_MINUS => '-', K_EQUALS => '='
    }
  end

  def update
    return if @game_over || @game_clear  # ゲームオーバーまたはクリアなら更新しない

    # 十字キーで発射位置を移動（@input_mode が false のときのみ）
    if !@input_mode
      @cannon_x -= 10 if Input.key_down?(K_LEFT) && @cannon_x > 0
      @cannon_x += 10 if Input.key_down?(K_RIGHT) && @cannon_x < Window.width
    end

    @cannonballs.each(&:update)

    # スペースキーで砲弾を発射または砲弾を破壊
    if Input.key_push?(K_SPACE) && !@shot_mode
      cannonball = Cannonball.new(@cannon_x, @cannon_y)
      cannonball.fire
      @cannonballs << cannonball
      @shot_mode = true
    elsif Input.key_push?(K_SPACE) && @shot_mode
      if (last_cannonball = @cannonballs.last)  # 最後に発射された砲弾があるか確認
        target_x = last_cannonball.x + (last_cannonball.image.width / 2) 
        target_y = last_cannonball.y

        hit_blocks = @blocks.select { |block| hit_block?(block, target_x, target_y) }
        if hit_blocks.any?
          hit_blocks.each do |block|
            @blocks.delete(block)
          end
          @score += hit_blocks.size
          @cannonballs.delete(last_cannonball)
        else
          @misses += 1
          @game_over = true if @misses >= 20
        end
        @shot_mode = false
      end
    end

    # 外れた砲弾の処理
    @cannonballs.each do |cannonball|
      if cannonball.out_of_bounds
        @cannonballs.delete(cannonball)
      end
    end
  end

  def hit_block?(block, x, y)
    x >= block.x && x <= block.x + block.image.width && y >= block.y && y <= block.y + block.image.height
  end

  def draw
    Window.draw(0, 0, @background)
    Window.draw(100, 50, @target)  # ターゲット画像の描画
    @blocks.each(&:draw)
    @cannonballs.each(&:draw)
    Window.draw_font(10, 10, "Score: #{@score}", @font)
    Window.draw_font(10, 40, "Misses: #{@misses}", @font)
    Window.draw(@cannon_x, @cannon_y, @cannon_image)  # 砲台の描画
    Window.draw_font(100, 50, "spaceキーでボールを発射" , Font.new(40, 'メイリオ'), color: [0, 0, 0])
    Window.draw_font(100, 100, "Altキーで答え入力", Font.new(40, 'メイリオ'), color: [0, 0, 0])
    
    # 文字入力モードのときに入力画面を描画
    draw_answer_mode if @input_mode

    # ゲームオーバー時のメッセージ
    if @game_over
      Window.draw_font(100, 400, "ゲームオーバー!!", Font.new(50, 'メイリオ'), color: [255, 0, 0])
    end

    # ゲームクリア時のメッセージ
    if @game_clear
      Window.draw_font(100, 400, "ゲームクリア!!", Font.new(50, 'メイリオ'), color: [0, 255, 0])
    end
  end

  def draw_start_screen
    Window.draw(0, 0, @start_background)
    Window.draw_font(100, 250, "Spaceキーでスタート！", Font.new(50, 'メイリオ', weight: true), color: [0, 0, 0])  
    Window.draw_font(100, 300, "Enterキーでゲームの説明", Font.new(50, 'メイリオ', weight: true), color: [0, 0, 0])
  end

  def draw_instructions_screen
    Window.draw(0, 0, @start_background)
    Window.draw_font(100, 100, "Instructions:", @font)
    Window.draw_font(100, 100, "ゲームの説明", Font.new(50, 'メイリオ', weight: true), color: [0, 0, 0])  
    Window.draw_font(100, 150, "矢印キーで大砲を動かす。", Font.new(40, 'メイリオ'), color: [0, 0, 0])  
    Window.draw_font(100, 200, "Space キーでボールを発射する。", Font.new(40, 'メイリオ'), color: [0, 0, 0])  
    Window.draw_font(100, 250, "二回目のSpace キーでボールを積み木にあてる。", Font.new(40, 'メイリオ'), color: [0, 0, 0]) 
    Window.draw_font(100, 300, "Altキーで答えを入力。", Font.new(40, 'メイリオ'), color: [0, 0, 0])
    Window.draw_font(100, 350, "答えを三回間違えたらゲームオーバー。", Font.new(40, 'メイリオ'), color: [0, 0, 0])
  end

  def alt_answer_mode
    @input_mode = true
    @input_text = ""  # 答え入力モードに入るときに入力をリセット
  end

  def check_answer
    if @input_text == @target_filename
      @game_clear = true  # 答えが正しければゲームクリア
    else
      @misses += 1  # 答えが間違っていればミスをカウント
      @game_over = true if @misses >= 3
      @input_mode = false
      @input_text = ""
    end
  end

  def handle_key_input
    # 文字入力モードの場合
    if @input_mode
      @key_to_char.each do |key, char|
        if Input.key_push?(key)
          @input_text += char
        end
      end

      # バックスペースキーで最後の文字を削除
      if Input.key_push?(K_BACKSPACE)
        @input_text.chop!
      end

      # Enterキーで答えをチェック
      if Input.key_push?(K_RETURN)
        check_answer
      end

    # 文字入力モードでない場合の処理
    else
      if Input.key_push?(K_LALT)
        alt_answer_mode
      end
    end
  end

  def draw_answer_mode
    Window.draw_font(100, 500, "答えを入力してください: #{@input_text}", Font.new(40, 'メイリオ'), color: [0, 0, 0])
  end
end

# メインのゲームループ
game = Game.new
start_screen = true
instructions_screen = false

Window.loop do
  if start_screen
    game.draw_start_screen
    if Input.key_push?(K_SPACE)
      start_screen = false
    elsif Input.key_push?(K_RETURN)
      instructions_screen = true
      start_screen = false
    end
  elsif instructions_screen
    game.draw_instructions_screen
    if Input.key_push?(K_ESCAPE)
      instructions_screen = false
      start_screen = true
    end
  else
    game.update
    game.draw
    game.handle_key_input

    # ゲームオーバーまたはクリア時の処理
    if game.game_over || game.game_clear
      Window.draw_font(100, 400, "ゲームオーバー!!", Font.new(50, 'メイリオ'), color: [255, 0, 0]) if game.game_over
      Window.draw_font(100, 400, "ゲームクリア!!", Font.new(50, 'メイリオ'), color: [0, 255, 0]) if game.game_clear
    end
  end
end

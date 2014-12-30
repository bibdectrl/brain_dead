require 'gosu'

module BrainDead
  CELL_WIDTH = 10 
  WIDTH = 100
  HEIGHT = 80
  SIZE = 100
  ALIVE = Gosu::Color::WHITE
  DYING = Gosu::Color::RED
  DEAD = Gosu::Color::BLACK
  PLAYER = Gosu::Color::GREEN
  BULLET = Gosu::Color::YELLOW
  PLAYER_DEAD = Gosu::Color::GRAY

  module State
    ALIVE = 1
    DYING = 10
    DEAD = 0
    DEAD_PLAYER = 666
  end

  Entity = Struct.new(:x, :y, :direction)

  class BrainDeadWindow < Gosu::Window
    attr_accessor :reader, :bullets
    def initialize
      super(WIDTH * CELL_WIDTH, HEIGHT * CELL_WIDTH, false, 6)
      self.caption = "Brain Dead"
      @plane = Plane.new
      @state = :go
      @alive = true
      @score_text = Gosu::Font.new(self, "Terminal", 20)
      @points = 0
      x = Random.rand(WIDTH)
      y = Random.rand(HEIGHT)
      @plane.field[[x, y-1]] = State::ALIVE
      @plane.field[[x,y]] = State::ALIVE
      @player = Entity.new(Random.rand(WIDTH), Random.rand(HEIGHT), :up)
      @bullets = []
      @millis = 0
    end
    
    def restart
      @plane = Plane.new
      x = Random.rand(WIDTH)
      y = Random.rand(HEIGHT)
      @plane.field[[x, y-1]] = State::ALIVE
      @plane.field[[x,y]] = State::ALIVE
      @player = Entity.new(Random.rand(WIDTH), Random.rand(HEIGHT), :up)
      @bullets = []
      @points = 0
      @alive = true
      @millis = 0
    end

    def draw
      draw_quad(
                @player.x * CELL_WIDTH,
                @player.y * CELL_WIDTH,
                PLAYER,
                @player.x * CELL_WIDTH + CELL_WIDTH,
                @player.y * CELL_WIDTH,
                PLAYER,
                @player.x * CELL_WIDTH + CELL_WIDTH,
                @player.y * CELL_WIDTH + CELL_WIDTH,
                PLAYER,
                @player.x * CELL_WIDTH,
                @player.y * CELL_WIDTH + CELL_WIDTH,
                PLAYER
      )
      
      @bullets.each do |b| draw_quad(
                b.x * CELL_WIDTH,
                b.y * CELL_WIDTH,
                BULLET,
                b.x * CELL_WIDTH + CELL_WIDTH,
                b.y * CELL_WIDTH,
                BULLET,
                b.x * CELL_WIDTH + CELL_WIDTH,
                b.y * CELL_WIDTH + CELL_WIDTH,
                BULLET,
                b.x * CELL_WIDTH,
                b.y * CELL_WIDTH + CELL_WIDTH,
                BULLET
      )
      end     
      
      @plane.field.each do |k, v|
        x, y = k
        case v 
        when State::ALIVE
          draw_quad(
                    x * CELL_WIDTH,
                    y * CELL_WIDTH,
                    ALIVE, 
                    x * CELL_WIDTH + CELL_WIDTH,
                    y * CELL_WIDTH, 
                    ALIVE, 
                    x * CELL_WIDTH + CELL_WIDTH,
                    y * CELL_WIDTH + CELL_WIDTH,
                    ALIVE, 
                    x * CELL_WIDTH, 
                    y * CELL_WIDTH + CELL_WIDTH,
                    ALIVE)
          
        when State::DYING
          draw_quad(
                    x * CELL_WIDTH, 
                    y * CELL_WIDTH,  
                    DYING, 
                    x * CELL_WIDTH + CELL_WIDTH,
                    y * CELL_WIDTH, 
                    DYING, 
                    x * CELL_WIDTH + CELL_WIDTH, 
                    y * CELL_WIDTH + CELL_WIDTH, 
                    DYING, 
                    x * CELL_WIDTH, 
                    y * CELL_WIDTH + CELL_WIDTH, 
                    DYING)
        when State::DEAD_PLAYER
          draw_quad(
                    x * CELL_WIDTH, 
                    y * CELL_WIDTH,  
                    PLAYER_DEAD, 
                    x * CELL_WIDTH + CELL_WIDTH,
                    y * CELL_WIDTH, 
                    PLAYER_DEAD, 
                    x * CELL_WIDTH + CELL_WIDTH, 
                    y * CELL_WIDTH + CELL_WIDTH, 
                    PLAYER_DEAD, 
                    x * CELL_WIDTH, 
                    y * CELL_WIDTH + CELL_WIDTH, 
                    PLAYER_DEAD
                    )
        end
      end
      @score_text.draw(@points, 10, 10, 10)
    end
    
    def needs_cursor?
      true
    end

    def update
      case @alive       
      when true
        @bullets.reject! {|b| b.x < 0 || b.y < 0 || b.x > WIDTH || b.y > HEIGHT}
        @bullets.each do |b|
          case b.direction
          when :up
            b.y -= 1
          when :down
            b.y += 1
          when :left
            b.x -= 1
          when :right
            b.x += 1
          end
          if @plane.field[[b.x, b.y]] == 1 then @points += 10; @plane.field[[b.x, b.y]] = 0 end
        end
        if @plane.field[[@player.x, @player.y]] != 0
          @plane.field[[@player.x, @player.y]] = 666
          @alive = false 
        end
        @millis += 10
        if @millis > 300 then @millis = 0; @plane.time_step end
        if button_down? Gosu::KbUp then @player.y -= 1 end
        if button_down? Gosu::KbDown then @player.y += 1 end
        if button_down? Gosu::KbLeft then @player.x -= 1 end
        if button_down? Gosu::KbRight then @player.x += 1 end
      when false
        if button_down? Gosu::KbEscape then exit end
        if button_down? Gosu::KbR then restart end
      end
    end
    
    def button_down id
      case @alive
        when true
        case id
        when Gosu::KbEscape
          exit
        when Gosu::KbLeft
          @player.direction = :left
        when Gosu::KbRight
          @player.direction = :right
        when Gosu::KbUp
          @player.direction = :up
        when Gosu::KbDown
          @player.direction = :down
        when Gosu::KbSpace
          case @player.direction
          when :up
            @bullets << Entity.new(@player.x, @player.y, :up)
          when :down
            @bullets << Entity.new(@player.x, @player.y, :down)
          when :left
            @bullets << Entity.new(@player.x, @player.y, :left)
          when :right
            @bullets << Entity.new(@player.x, @player.y, :right)
          end
        end
      end
    end
  end

  class Plane

    attr_reader :field

    def initialize
      @field = Hash.new(0)
    end

    def time_step
      new_field = Hash.new(0)
      @field.each do |k, v|
        x, y = k
        if @field[[x, y]] == State::ALIVE
          new_field[[(x+1) % WIDTH, y]] +=1 
          new_field[[(x+1) % WIDTH, (y+1) % HEIGHT]] += 1 
          new_field[[(x+1) % WIDTH, (y-1) % HEIGHT]] += 1 
          new_field[[x, (y+1) % WIDTH]] += 1
          new_field[[x, (y-1) % WIDTH]] += 1
          new_field[[(x-1) % WIDTH, y]] += 1
          new_field[[(x-1) % WIDTH, (y+1) % HEIGHT]] += 1
          new_field[[(x-1) % WIDTH, (y-1) % HEIGHT]] += 1
        end
      end
      @field.each do |k, v|
        x, y = k
        if @field[[x, y]] == State::ALIVE
          new_field[[x, y]] = State::DYING
        elsif @field[[x, y]] == State::DYING
          new_field[[x,y]] = State::DEAD
        elsif new_field[[x, y]] % 10 == 2 
          new_field[[x,y]] = State::ALIVE
        else new_field[[x, y]] = State::DEAD
        end
      end
      @field = new_field
    end
  end
end

BrainDead::BrainDeadWindow.new.show

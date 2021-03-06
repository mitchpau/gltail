class FontStore
  @list_base = 0
  @font = []
  @buffers = nil

  @font_texture = nil

  WIDTH   =  8 / 256.0
  HEIGHT  = 13 / 256.0
  
  def self.generate_textures
    if @font_texture.nil?
      @font_texture = glGenTextures(1)[0]

      File.open("#{File.dirname(__FILE__)}/font.bin") do |f|
        @font = Marshal.load(f)
      end

      font_data = []

      # Add missing pixels to increase height by 3
      32.upto(255) do |c|
        @font[c] += @font[c] + [0,0,0].pack("C*") * 24
      end

      0.upto(196607) do |i|
        font_data[i] = 0
      end

      # Re-order bitmap data into one 256x256 texture
      32.upto(255) do |c|
        row = (c - 32) / 16
        col = (c - 32) % 16

        offset = row * 256*16*3 + col*8*3
        0.upto(15) do |y|
          0.upto(7) do |x|
            font_data[offset + y*256*3 + x*3 +0] = @font[c][y*8*3 + x*3 + 0]
            font_data[offset + y*256*3 + x*3 +1] = @font[c][y*8*3 + x*3 + 1]
            font_data[offset + y*256*3 + x*3 +2] = @font[c][y*8*3 + x*3 + 2]
          end
        end

      end

#      File.open("lib/font_256.bin", "wb") do |f|
#        Marshal.dump(font_data, f)
#      end

      font_data = font_data.pack("C*")

      glBindTexture(GL_TEXTURE_2D, @font_texture)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
#      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
#      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
#      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP)
#      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP)
      glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)
      #    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL)
#    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE)
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 256, 256, 0, GL_RGB, GL_UNSIGNED_BYTE, font_data)

      glBindTexture(GL_TEXTURE_2D, 0)
    end
  end

  def self.generate_font
    self.generate_textures
    return

    # Ignore the rest for now, used only to create font.bin

#    glPushMatrix
#    glViewport(0, 0, 8, 15)
#    glMatrixMode(GL_PROJECTION)
#    glLoadIdentity()

#    glOrtho(0, 8, 13, 0, -1.0, 1.0)

#    glMatrixMode(GL_MODELVIEW)
#    glLoadIdentity()
#    glTranslate(0, 0, 0)

#    glMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, ( [1.0, 1.0, 1.0, 1.0]  ) )
#    32.upto(255) do |c|
#      glClearColor(0.0, 0.0, 0.0, 1.0)
#      glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

#      glRasterPos(0,0)
#      begin
#        glutBitmapCharacter(GLUT_BITMAP_8_BY_13, c)
#      rescue RangeError
#        glutBitmapCharacterX(c)
#      end

#      glBindTexture(GL_TEXTURE_2D, @textures[c])
#      glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 0, 13, 8, 13, 0)


#      glBindTexture(GL_TEXTURE_2D, 0)
#    end
#    glClearColor(0.0, 0.0, 0.0, 1.0)
#    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

#    glPopMatrix

  end

  def self.render_char(engine, c, pos)
    char_size = engine.char_size

    base = c-32

    offsetx = ((base%16) ) / (32.0)
    offsety = ((base/16) * 16) / (256.0)

    pos_offset = char_size * pos

    glTexCoord2f(offsetx,offsety)
    glNormal3f(1.0, 1.0, 0.0)
    glVertex3f(pos_offset, 0, 0.0)

    glTexCoord2f(offsetx+WIDTH,offsety)
    glNormal3f(1.0, 1.0, 0.0)
    glVertex3f(pos_offset + char_size, 0.0, 0.0)

    glTexCoord2f(offsetx+WIDTH,offsety + HEIGHT)
    glNormal3f(1.0, 1.0, 0.0)
    glVertex3f(pos_offset + char_size, engine.line_size, 0.0)

    glTexCoord2f(offsetx,offsety + HEIGHT)
    glNormal3f(1.0, 1.0, 0.0)
    glVertex3f(pos_offset, engine.line_size, 0.0)
  end


  def self.render_string(engine, text, cache, pos)
    list = nil
    list = BlobStore.get(text) if cache
    if list.nil?
      list = glGenLists(1)
      glNewList(list, GL_COMPILE)
      glEnable(GL_BLEND)
      glBindTexture(GL_TEXTURE_2D, @font_texture)
      glBegin(GL_QUADS)
      text.each_byte do |c|
        self.render_char(engine, c, pos) unless c == 32
        pos += 1
      end
      glEnd
      glBindTexture(GL_TEXTURE_2D, 0)
      glDisable(GL_BLEND)
      glEndList
      BlobStore.put(text,list) if cache
    end 
    list
  end 

end

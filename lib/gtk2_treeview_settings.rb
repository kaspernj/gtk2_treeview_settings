#This class handels appending and reading data from a treeview with dynamic columns. It tracks the columns based on given symbol-IDs.
#===Examples
#  @tv_settings = Gtk2_treeview_settings.new(
#    :tv => @gui["tvTimelogs"],
#    :col_ids => {
#      0 => :id,
#      1 => :name
#    }
#  )
class Gtk2_treeview_settings
  attr_reader :tv
  
  def initialize(args)
    @args = args
    @tv = @args[:tv]
    @renderers = {}
    
    #Set the initial order of the columns so we can recognize them later.
    @col_ids = {}
    count = 0
    @tv.columns.each do |col|
      @col_ids[count] = col.__id__
      count += 1
    end
    
    #Remember IDs for columns.
    if @args[:col_ids]
      @saved_ids = {}
      @args[:col_ids].each do |key, val|
        @saved_ids[val] = @tv.columns[key].__id__
      end
    end
  end
  
  def cellrenderer_for_id(id)
    col_no = self.col_no_for_id(id)
    col = tv.columns[col_no]
    renderer = col.cell_renderers.first
    raise Errno::ENOENT, "Could not find cell-renderer for that ID: '#{id}', '#{col_no}'." if !renderer
    return renderer
  end
  
  #Returns a column-number for a specific ID (given at initialize-time).
  def col_no_for_id(id)
    obj_id = @saved_ids[id]
    raise "No column by that ID: '#{id}'." if !obj_id
    
    count = 0
    @tv.columns.each do |col|
      return count if col.__id__ == obj_id
      count += 1
    end
    
    raise "Could not find column by that ID: '#{id}'."
  end
  
  def col_orig_no_for_id(id)
    col_obj_id = nil
    @saved_ids.each do |key, val|
      if key == id
        col_obj_id = val
        break
      end
    end
    
    raise "Could not find column by ID: '#{id}'." if !col_obj_id
    
    @col_ids.each do |key, val|
      if val == col_obj_id
        return key
      end
    end
    
    raise "Could not find column number by that ID: '#{id}'."
  end
  
  #Appends the given data to the treeview. Only works with Gtk::ListStore.
  #===Examples
  #  gset.append(:id => 0, :name => "Kasper") #=> {:iter => Gtk::TreeIter-object}
  def append(data)
    if @tv.model.is_a?(Gtk::TreeStore)
      iter = @tv.model.append(nil)
    else
      iter = @tv.model.append
    end
    
    data.each do |key, val|
      col_no = self.col_no_for_id(key)
      col_no_orig = self.col_orig_no_for_id(key)
      col = tv.columns[col_no]
      renderer = col.cell_renderers.first
      
      if renderer.is_a?(Gtk::CellRendererText)
        iter[col_no_orig] = val.to_s
      elsif renderer.is_a?(Gtk::CellRendererToggle)
        iter[col_no_orig] = Knj::Strings.yn_str(val, 1, 0)
      elsif renderer.is_a?(Gtk::CellRendererCombo)
        iter[col_no_orig] = val.to_s
      else
        raise "Unknown renderer: '#{renderer.class.name}'."
      end
    end
    
    return {:iter => iter}
  end
  
  #Appens the given data the the treeview in hash-form which gives the posibility for a parent element when using TreeStore.
  #===Examples
  #  gset.append_adv(:parent => parent_iter, :data => {:id => 0, :name => "Kasper"}) #=> {:iter => Gtk::TreeIter-object}
  def append_adv(args)
    if @tv.model.is_a?(Gtk::TreeStore)
      iter = @tv.model.append(args[:parent])
    else
      iter = @tv.model.append
    end
    
    args[:data].each do |key, val|
      col_no = self.col_no_for_id(key)
      col_no_orig = self.col_orig_no_for_id(key)
      col = tv.columns[col_no]
      renderer = col.cell_renderers.first
      
      if renderer.is_a?(Gtk::CellRendererText)
        iter[col_no_orig] = val.to_s
      elsif renderer.is_a?(Gtk::CellRendererToggle)
        iter[col_no_orig] = Knj::Strings.yn_str(val, 1, 0)
      elsif renderer.is_a?(Gtk::CellRendererCombo)
        iter[col_no_orig] = val.to_s
      else
        raise "Unknown renderer: '#{renderer.class.name}'."
      end
    end
    
    return {:iter => iter}
  end
end
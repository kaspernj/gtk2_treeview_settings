# This class handels appending and reading data from a treeview with dynamic columns. It tracks the columns based on given symbol-IDs.
# === Examples
#  @treeview_settings = GtkTreeviewSettings.new(
#    :tv => @gui["tvTimelogs"],
#    :col_ids => {
#      0 => :id,
#      1 => :name
#    }
#  )
class GtkTreeviewSettings
  attr_reader :treeview

  def initialize(args)
    @args = args
    @treeview = @args.fetch(:treeview)
    @renderers = {}

    # Set the initial order of the columns so we can recognize them later.
    @col_ids = {}
    count = 0
    @treeview.columns.each do |col|
      @col_ids[count] = col.__id__
      count += 1
    end

    # Remember IDs for columns.
    if @args[:col_ids]
      @saved_ids = {}
      @args.fetch(:col_ids).each do |key, val|
        @saved_ids[val] = @treeview.columns[key].__id__
      end
    end
  end

  def column(number)
    @treeview.get_column(number)
  end

  def cellrenderer_for_id(id)
    col_no = col_no_for_id(id)
    col = @treeview.columns[col_no]
    renderer = col.cell_renderers.first
    raise Errno::ENOENT, "Could not find cell-renderer for that ID: '#{id}', '#{col_no}'." unless renderer
    renderer
  end

  # Returns a column-number for a specific ID (given at initialize-time).
  def col_no_for_id(id)
    obj_id = @saved_ids[id]
    raise "No column by that ID: '#{id}'." unless obj_id

    count = 0
    @treeview.columns.each do |col|
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

    raise "Could not find column by ID: '#{id}'." unless col_obj_id

    @col_ids.each do |key, val|
      return key if val == col_obj_id
    end

    raise "Could not find column number by that ID: '#{id}'."
  end

  # Appends the given data to the treeview. Only works with Gtk::ListStore.
  #===Examples
  #  gset.append(:id => 0, :name => "Kasper") #=> {:iter => Gtk::TreeIter-object}
  def append(data)
    if @treeview.model.is_a?(Gtk::TreeStore)
      iter = @treeview.model.append(nil)
    else
      iter = @treeview.model.append
    end

    data.each do |key, val|
      col_no = col_no_for_id(key)
      col_no_orig = col_orig_no_for_id(key)
      col = @treeview.columns[col_no]
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

    {iter: iter}
  end

  # Appens the given data the the treeview in hash-form which gives the posibility for a parent element when using TreeStore.
  #===Examples
  #  gset.append_adv(:parent => parent_iter, :data => {:id => 0, :name => "Kasper"}) #=> {:iter => Gtk::TreeIter-object}
  def append_adv(args)
    if @treeview.model.is_a?(Gtk::TreeStore)
      iter = @treeview.model.append(args[:parent])
    else
      iter = @treeview.model.append
    end

    args[:data].each do |key, val|
      col_no = col_no_for_id(key)
      col_no_orig = col_orig_no_for_id(key)
      col = @treeview.columns[col_no]
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

    {iter: iter}
  end

  ALLOWED_ARGS_FOR_SETUP = [:cols, :reorderable, :sortable, :type]
  # Initializes a treeview with a model and a number of columns. Returns a hash containing various data like the renderers.
  #===Examples
  # tv_settings.set(["ID", "Name"])
  def setup(rargs)
    ret = {
      renderers: []
    }

    if rargs.is_a?(Array)
      columns = rargs
      rargs = {}
    else
      columns = rargs[:cols]
    end


    # Default arguments.
    rargs = {
      reorderable: true,
      sortable: true
    }.merge!(rargs)

    rargs.each do |key, _val|
      raise "Invalid argument: '#{key}'." unless ALLOWED_ARGS_FOR_SETUP.include?(key)
    end

    # Spawn store.
    model_args = []
    columns.each do |args|
      args = {type: :string, title: args} if args.is_a?(String)

      if args[:type] == :string
        model_args << String
      elsif args[:type] == :toggle
        model_args << Integer
      elsif args[:type] == :combo
        model_args << String
      else
        raise "Invalid type: '#{args[:type]}'."
      end
    end

    if rargs[:type] == :treestore
      list_store = Gtk::TreeStore.new(*model_args)
    else
      list_store = Gtk::ListStore.new(*model_args)
    end

    @treeview.model = list_store

    count = 0
    columns.each do |args|
      args = {type: :string, title: args} if args.is_a?(String)

      if args[:type] == :string
        if args[:markup]
          col_args = {markup: count}
        else
          col_args = {text: count}
        end

        renderer = Gtk::CellRendererText.new
        col = Gtk::TreeViewColumn.new(args[:title], renderer, col_args)
        col.resizable = true
      elsif args[:type] == :toggle
        renderer = Gtk::CellRendererToggle.new
        col = Gtk::TreeViewColumn.new(args[:title], renderer, active: count)
      elsif args[:type] == :combo
        renderer = Gtk::CellRendererCombo.new
        renderer.text_column = 0
        renderer.model = args[:model] if args.key?(:model)
        renderer.has_entry = args[:has_entry] if args.key?(:has_entry)

        if args[:markup]
          col_args = {markup: count}
        else
          col_args = {text: count}
        end

        col = Gtk::TreeViewColumn.new(args[:title], renderer, col_args)
        col.resizable = true
      else
        raise "Invalid type: '#{args[:type]}'."
      end

      col.spacing = 0
      col.reorderable = rargs[:reorderable] if !args.key?(:reorderable) || args[:reorderable]

      if !rargs[:sortable]
        col.sort_column_id = -1
      else
        col.sort_column_id = count
      end

      if args.key?(:fixed_width)
        col.sizing = Gtk::TreeViewColumn::FIXED
      else
        col.sizing = :autosize
      end

      [:min_width, :max_width, :fixed_width, :expand, :spacing, :reorderable].each do |arg|
        col.__send__("#{arg}=", args[arg]) if args.key?(arg)
      end

      [:width_chars, :wrap_mode, :wrap_width].each do |arg|
        renderer.__send__("#{arg}=", args[arg]) if args.key?(arg)
      end

      @treeview.append_column(col)
      ret[:renderers] << renderer
      count += 1
    end

    ret
  end

  # Gets the selected data from the treeview.
  #===Examples
  # tv.selection #=> [1, "Kasper"]
  def selection
    selected = @treeview.selection.selected_rows
    return nil if !@treeview.model || selected.size <= 0

    iter = @treeview.model.get_iter(selected[0])
    returnval = []
    columns = @treeview.columns

    count = 0
    columns.each do
      returnval[count] = iter[count]
      count += 1
    end

    returnval
  end
end

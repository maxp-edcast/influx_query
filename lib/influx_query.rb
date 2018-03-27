class InfluxQuery

  attr_reader :params, :conditions, :select_columns, :source, :client

  def initialize(
    source:, client:, conditions: nil, params: nil, select_columns: nil
  )
    @conditions     = conditions || []
    @params         = params || {}
    @select_columns = select_columns || ["*"]
    @source         = source
    @client         = client
  end

  def resolve
    client.query finalize, params: params
  end

  def finalize
    "#{finalize_subquery} ;"
  end

  def finalize_subquery
    (
      "select #{@select_columns.join(",")} " +
      "from #{@source}" +
      "#{finalize_conditions}"
    ).tap do |str|
      str << " GROUP BY %{group_by}" if @params[:group_by]
      str << " LIMIT %{limit}" if @params[:limit]
      str << " OFFSET %{offset}" if @params[:offset]
    end
  end

  def finalize_conditions
    return "" unless @conditions.any?
    " where #{@conditions.join(" AND ")}"
  end

  def limit!(limit)
    return self unless limit
    limit = limit.to_i
    raise(ArgumentError, "Cannot add a limit of 0") if limit.zero?
    @params.merge! limit: limit
    self
  end

  def offset!(offset)
    return self unless offset
    offset = offset.to_i
    @params.merge! offset: offset
    self
  end

  def group_by!(group_by)
    return self unless group_by
    @params.merge! group_by: group_by
    self
  end

  def add_conditions!(properties, operator: "AND", wrap_clause: false)
    clause = build_query_constraints(
      properties: properties,
      operator: operator
    )
    clause = "(#{clause})" if wrap_clause
    @conditions.push clause
    self
  end

  def add_where_in_filter!(param_key_base, col_name, vals)
    return self unless vals.any?
    properties = vals.map.with_index do |val, idx|
      param_key = :"#{param_key_base}_#{idx}"
      @params.merge! param_key => val
      {
        key: col_name,
        operator: "=",
        value: "%{#{param_key}}"
      }
    end
    add_conditions!(properties, operator: "OR", wrap_clause: true)
  end

  # Most of the filters have the same structure.
  def filter!(param_name, col_name, operator, val)
    return self unless val
    @params.merge!(param_name => val)
    add_conditions! [{
      key: col_name,
      operator: operator,
      value: "%{#{param_name}}"
    }]
  end

  def add_time_filters!(start_date: nil, end_date: nil, **_opts)
    start_date ||= (Time.now.utc - 7.days).beginning_of_day.to_i
    end_date ||= Time.now.utc.end_of_day.to_i
    @params.merge! start_date: start_date, end_date: end_date
    add_conditions! [
      { key: 'time', operator: ">=", value: "%{start_date}s" },
      { key: 'time', operator: "<=", value: "%{end_date}s" }
    ], operator: "AND"
  end

  def build_query_constraints(properties: [], operator: 'AND')
    conditions = []
    properties.each do |property|
      # Influx requires different quotation types for different situations.
      # no quotes are used here:
      #   where time > 123123123s (s -> seconds)
      # but single quotes are used here
      #   where controller_action = 'sessions_controller#create'
      value = if property[:value].is_a?(String) && property[:key] != 'time'
        "'#{property[:value]}'"
      else
        property[:value]
      end
      conditions << "#{property[:key]} #{property[:operator]} #{value}"
    end
    conditions.join(" #{operator} ")
  end

end
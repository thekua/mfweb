class FlexibleTr < Mfweb::Article::PaperTransformer
  def handle_database_list anElement
    @html.table('database-list') do 
      @html.th {@html << 'database'}
      @html.th {@html << 'model'}
      anElement.css('database').sort_by{|e| e['name']}.each do |e|
        handle e
      end
    end
  end
  def handle_database anElement
    @html.tr do
      @html.td do
        @html.a_ref(anElement['uri']) {@html << anElement['name']}
      end
      @html.td {@html << anElement.parent['name']}
    end
  end
  def handle_databases_by_model anElement
    DatabaseByModelTr.new(@html, @root).render
  end
  def handle_semantic_markup anElement
    @html.h(2) {@html << "Semantic Markup"}
    apply anElement
  end
end

class DatabaseByModelTr < Mfweb::Core::Transformer
  def handle_paper anElement
    @html.table("db-by-model") do
      @html.th {@html << 'model'}
      @html.th {@html << 'database'}
      @root.css("database-list data-model").
        sort_by{|e| e['name']}.each {|e| handle e}
    end
  end
  def handle_data_model anElement
    apply anElement
  end
  def handle_database anElement
    @html.tr do
      @html.td {@html << anElement.parent['name']}
      @html.td do
        @html.a_ref(anElement['uri']) {@html << anElement['name']}
      end
    end    
  end
end

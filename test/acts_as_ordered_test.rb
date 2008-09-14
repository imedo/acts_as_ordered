require File.dirname(__FILE__) + '/abstract_unit'

class ActsAsOrderedTest < Test::Unit::TestCase
  def setup
    create_articles(9)
  end
  
  def teardown
    Article.delete_all
  end
  
  def test_should_find_next_or_previous
    articles = Article.find(:all)
    mid = articles[5]
    assert_equal articles[4].id, Article.find(:previous, :source => mid).id
    assert_equal articles[6].id, Article.find(:next, :source => mid).id
  end
  
  def test_should_find_next_or_previous_from_instance
    articles = Article.find(:all)
    mid = articles[5]
    assert_equal articles[4].id, mid.find_prev.id
    assert_equal articles[6].id, mid.find_next.id
  end
  
  def test_should_find_both
    articles = Article.find(:all)
    mid = articles[5]
    assert_equal [articles[6].id, articles[4].id], mid.find_next_and_prev.collect(&:id)
  end
  
  def test_should_find_next_or_previous_with_order_directive
    articles = Article.find(:all, :order => 'author_id')
    mid = articles[1]
    
    # Author ids are id mod 3, i.e. 0 1 2 0 1 2 0 1 2 => model ids are 1 4 7 2 5 8 3 6 9
    assert_equal [1, 4, 7, 2, 5, 8, 3, 6, 9], articles.collect(&:id)
    
    assert_not_equal articles[0].id, mid.find_prev.id
    assert_not_equal articles[2].id, mid.find_next.id
    
    assert_equal articles[0].id, mid.find_prev(:order => 'author_id').id
    assert_equal articles[2].id, mid.find_next(:order => 'author_id').id
  end
  
  def test_should_work_correctly_with_reverse_order_directive
    articles = Article.find(:all, :order => 'author_id DESC')
    mid = articles[1]
    
    # Author ids are id mod 3, i.e. 0 1 2 0 1 2 0 1 2 => model ids are 3 6 9 2 5 8 1 4 7
    assert_equal [3, 6, 9, 2, 5, 8, 1, 4, 7], articles.collect(&:id)

    assert_not_equal articles[0].id, mid.find_prev.id
    assert_not_equal articles[2].id, mid.find_next.id

    assert_equal articles[0].id, mid.find_prev(:order => 'author_id DESC').id
    assert_equal articles[2].id, mid.find_next(:order => 'author_id DESC').id
  end
  
  def test_should_find_next_or_previous_with_multiple_order_directives
    articles = Article.find(:all, :order => 'author_id DESC, id DESC')
    mid = articles[1]
    
    # Author ids are id mod 3, i.e. 0 1 2 0 1 2 0 1 2 => model ids are 9 6 3 8 5 2 7 4 1
    assert_equal [9, 6, 3, 8, 5, 2, 7, 4, 1], articles.collect(&:id)

    assert_not_equal articles[0].id, mid.find_prev.id
    assert_not_equal articles[2].id, mid.find_next.id

    assert_equal articles[0].id, mid.find_prev(:order => 'author_id DESC, id DESC').id
    assert_equal articles[2].id, mid.find_next(:order => 'author_id DESC, id DESC').id
  end
  
  def test_should_find_next_or_previous_with_conditions
    articles = Article.find(:all, :conditions => { :author_id => 1 })
    mid = articles[1]
    
    # Author ids are id mod 3, i.e. 0 1 2 0 1 2 0 1 2 => model ids are 2 5 8
    assert_equal [2, 5, 8], articles.collect(&:id)
    
    assert_not_equal articles[0].id, mid.find_prev.id
    assert_not_equal articles[2].id, mid.find_next.id
    
    assert_equal articles[0].id, mid.find_prev(:conditions => { :author_id => 1 }).id
    assert_equal articles[2].id, mid.find_next(:conditions => { :author_id => 1 }).id
  end
  
  def test_should_find_next_or_previous_with_order_and_conditions
    articles = Article.find(:all, :conditions => { :author_id => 1 }, :order => 'id DESC')
    mid = articles[1]
    
    # Author ids are id mod 3, i.e. 0 1 2 0 1 2 0 1 2 => model ids are 8 5 2
    assert_equal [8, 5, 2], articles.collect(&:id)

    assert_not_equal articles[0].id, mid.find_prev.id
    assert_not_equal articles[2].id, mid.find_next.id
    
    assert_equal articles[0].id, mid.find_prev(:conditions => { :author_id => 1 }, :order => 'id DESC').id
    assert_equal articles[2].id, mid.find_next(:conditions => { :author_id => 1 }, :order => 'id DESC').id
  end
  
  def test_should_return_nil_if_there_is_no_previous_element
    articles = Article.find(:all, :conditions => { :author_id => 1 }, :order => 'id DESC')
    mid = articles[0]
    
    assert_nil mid.find_prev(:conditions => { :author_id => 1 }, :order => 'id DESC')
  end
  
  def test_should_return_nil_if_there_is_no_next_element
    articles = Article.find(:all, :conditions => { :author_id => 1 }, :order => 'id DESC')
    mid = articles[2]
    
    assert_nil mid.find_next(:conditions => { :author_id => 1 }, :order => 'id DESC')
  end
  
protected
  def create_articles(num = 9)
    num.times do |i|
      a = Article.new(:author_id => i % 3)
      a.id = i + 1
      a.save
    end
  end
end

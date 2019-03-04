require 'test_helper'

class ActsAsMarkerTest < ActiveSupport::TestCase
  # Config

  test 'a_users_marker_name_should_be_user' do
    assert_equal :user, User.marker_name
  end

  # Methods

  test 'user.favorite_foods' do
    u1, u2 = get(User, 2)
    f1, f2 = get(Food, 2)
    assert_equal [], u1.favorite_foods
    u1.favorite_foods << f1
    assert_equal [f1], u1.favorite_foods
    u2.favorite_foods << [f1, f2]
    assert_equal [f1, f2], u2.favorite_foods
  end

  test 'user.foods_marked_as' do
    u1, u2 = get(User, 2)
    f1, f2 = get(Food, 2)
    assert_equal [], u1.foods_marked_as(:favorite)
    u1.foods_marked_as(:favorite) << f1
    assert_equal [f1], u1.foods_marked_as(:favorite)
    u2.foods_marked_as(:favorite) << [f1, f2]
    assert_equal [f1, f2], u2.foods_marked_as(:favorite)
  end

  test 'user.foods_marked_as_favorite' do
    u1, u2 = get(User, 2)
    f1, f2 = get(Food, 2)
    assert_equal [], u1.foods_marked_as_favorite
    u1.foods_marked_as_favorite << f1
    assert_equal [f1], u1.foods_marked_as_favorite
    u2.foods_marked_as_favorite << [f1, f2]
    assert_equal [f1, f2], u2.foods_marked_as_favorite
  end

  test 'user.set_mark_to' do
    u1, u2 = get(User, 2)
    f1, f2 = get(Food, 2)
    assert_equal [], u1.favorite_foods
    u1.set_mark :favorite, f1
    assert_equal [f1], u1.favorite_foods
    u2.set_mark :favorite, [f1, f2]
    assert_equal [f1, f2], u2.favorite_foods
  end

  test 'user.remove_mark_from' do
    u1 = get(User)
    f1, f2 = get(Food, 2)
    u1.favorite_foods << [f1, f2]
    assert_equal [f1, f2], u1.favorite_foods
    u1.remove_mark :favorite, f1
    assert_equal [f2], u1.favorite_foods
  end
  test 'user.favorite_foods.delete' do
    u1 = get(User)
    f1, f2 = get(Food, 2)
    u1.favorite_foods << [f1, f2]
    assert_equal [f1, f2], u1.favorite_foods
    u1.favorite_foods.delete f1
    assert_equal [f2], u1.favorite_foods
  end

  test 'user.hated_food' do
    u1 = get(User)
    f1, f2 = get(Food, 2)

    u1.hated_foods << f1
    u1.favorite_foods << f2
    assert_equal [f1], u1.hated_foods
    assert_equal [f2], u1.favorite_foods
  end

  # Errors

  test 'markers can mark allowed markables' do
    marker = User.create name: 'marker'
    markable = Food.create name: 'markable'

    marker.favorite_foods << markable
    assert_equal [markable], marker.favorite_foods
    assert_equal [marker], markable.users_have_marked_as_favorite
  end

  test "markers can't mark not allowed markables" do
    marker = User.create name: 'marker'
    markable = Drink.create name: 'markable'

    assert_raise(NoMethodError) do
      marker.favorite_drinks
    end
    assert_raise(NoMethodError) do
      markable.users_have_marked_as_favorite
    end
    assert_raise(Markable::NotAllowedMarker) do
      marker.favorite_foods << markable
    end
    assert_raise(Markable::NotAllowedMarker) do
      marker.set_mark :favorite, markable
    end
  end

  test "marker can't mark not markable" do
    marker1 = User.create name: 'marker'
    marker2 = User.create name: 'marker'

    assert_raise(Markable::WrongMark) do
      marker1.set_mark :favorite, marker2
    end
    assert_raise(Markable::WrongMarkableType) do
      marker1.set_mark :favorite, 'STRING'
    end
    assert_raise(Markable::WrongMark) do
      marker1.favorite_foods << marker2
    end
    assert_raise(Markable::WrongMarkableType) do
      marker1.favorite_foods << 'STRING'
    end
  end

  test 'errors in mark removal' do
    u1, u2 = get(User, 2)
    f1, f2 = get(Food, 2)
    u1.favorite_foods << [f1, f2]
    u2.favorite_foods << [f1, f2]
    assert_equal [f1, f2], u1.favorite_foods
    assert_equal [f1, f2], u2.favorite_foods

    assert_raise(Markable::WrongMarkerType) do
      f1.users_have_marked_as_favorite.delete(f2)
    end
    assert_raise(Markable::WrongMarkerType) do
      f1.users_have_marked_as_favorite.delete('STRING')
    end
    assert_raise(NoMethodError) do
      u1.users_have_marked_as_favorite.delete(u2)
    end

    assert_raise(Markable::WrongMarkerType) do
      f1.unmark :favorite, by: f2
    end
    assert_raise(Markable::WrongMarkerType) do
      f1.unmark :favorite, by: 'STRING'
    end
    assert_raise(Markable::WrongMarkableType, NoMethodError) do
      u1.remove_mark :favorite, by: f1
    end

    assert_raise(Markable::WrongMark) do
      u1.favorite_foods.delete u2
    end
    assert_raise(Markable::WrongMarkableType) do
      u1.favorite_foods.delete 'STRING'
    end
    assert_raise(NoMethodError) do
      f1.favorite_foods.delete f2
    end
  end

  # Lifecycle

  test 'marks are deleted when marker is destroyed' do
    u1 = get(User)
    f1 = get(Food)
    assert_difference 'f1.markable_marks.count' do
      u1.set_mark :favorite, f1
    end
    assert_difference 'f1.markable_marks.count', -1 do
      u1.destroy
    end
  end
end

# name: Watch Category
# about: Watches a category for all the users in a particular group
# version: 0.3
# authors: Arpit Jalan
# url: https://github.com/discourse/discourse-watch-category-mcneel

module ::WatchCategory

  def self.watch_category!
    groups_cats = {
      # 'group' => ['category', 'another-top-level-category', ['parent-category', 'sub-category']],
      # 'everyone' makes every user watch the listed categories
      # 'everyone' => ['announcements']
      'team-leaders' => ['team-leaders'],
      'berlin-team' => [['local-teams','berlin']],
      'bonn-team' => [['local-teams','bonn']],
      'frankfurt-team' => [['local-teams','frankfurt']],
      'heidelberg-team' => [['local-teams','heidelberg']],
      'academic-team' => [['ressort-teams','academic']],
      'outreach-team' => [['ressort-teams','outreach']],
      'staff' => ['staff']
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching)

    groups_cats = {
      'everyone' => ['news']
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :watching_first_post)

    groups_cats = {
      'berlin-team' => ['local-teams'],
      'bonn-team' => ['local-teams'],
      'frankfurt-team' => ['local-teams'],
      'heidelberg-team' => ['local-teams'],
      'academic-team' => ['ressort-teams'],
      'outreach-team' => ['ressort-teams'],
      'everyone' => ['lounge'],
      'everyone' => ['site-feedback'],
      'everyone' => ['knowledge-base']
    }
    WatchCategory.change_notification_pref_for_group(groups_cats, :regular)
  end

  def self.change_notification_pref_for_group(groups_cats, pref)
    groups_cats.each do |group_name, cats|
      cats.each do |cat_slug|

        # If a category is an array, the first value is treated as the top-level category and the second as the sub-category
        if cat_slug.respond_to?(:each)
          category = Category.find_by_slug(cat_slug[1], cat_slug[0])
        else
          category = Category.find_by_slug(cat_slug)
        end
        group = Group.find_by_name(group_name)

        unless category.nil? || group.nil?
          if group_name == 'everyone'
            User.all.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          else
            group.users.each do |user|
              watched_categories = CategoryUser.lookup(user, pref).pluck(:category_id)
              CategoryUser.set_notification_level_for_category(user, CategoryUser.notification_levels[pref], category.id) unless watched_categories.include?(category.id)
            end
          end
        end

      end
    end
  end

end

after_initialize do
  module ::WatchCategory
    class WatchCategoryJob < ::Jobs::Scheduled
      every 1.hours

      def execute(args)
        WatchCategory.watch_category!
      end
    end
  end
end

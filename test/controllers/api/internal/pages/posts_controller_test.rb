require "test_helper"

class API::Internal::Pages::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @page = workspaces(:one).pages.find_by(slug: 'blog')
  end

  test "should create post" do
    sign_in_as(users(:lazaro_nixon))
    assert_difference('Post.count') do
      post api_internal_pages_posts_url(page_id: @page.id), params: { title: 'Hello world!' }, as: :json
    end
    assert_response :created
  end

  test "should publish post, when author set" do
    sign_in_as(users(:lazaro_nixon))
    assert_not posts(:post_with_authors).published?

    post api_internal_pages_post_publish_url(page_id: @page.id, post_id: posts(:post_with_authors).id)
    posts(:post_with_authors).reload

    assert_response :ok
    assert posts(:post_with_authors).published?
  end

  test "should not publish post, when author is not set" do
    sign_in_as(users(:lazaro_nixon))
    assert_not posts(:one).published?

    post api_internal_pages_post_publish_url(page_id: @page.id, post_id: posts(:one).id)
    posts(:one).reload

    assert_response :unprocessable_entity
    assert_not posts(:one).published?
  end

  test "should update post" do
    sign_in_as(users(:lazaro_nixon))

    patch api_internal_pages_post_url(page_id: @page.id, id: posts(:one).id), params: { title: 'Hello world!' }, as: :json
    posts(:one).reload

    assert_response :ok
    assert_equal 'Hello world!', posts(:one).title
  end

  test "should not delete authors from post if none sent" do
    sign_in_as(users(:lazaro_nixon))
    posts(:one).update(authors: [authors(:one)])

    patch api_internal_pages_post_url(page_id: @page.id, id: posts(:one).id), params: { title: 'Hello world!' }, as: :json
    posts(:one).reload

    assert_response :ok
    assert_equal 1, posts(:one).authors.count
  end

  test "should delete authors from post if empty array is sent" do
    sign_in_as(users(:lazaro_nixon))
    posts(:one).update(authors: [authors(:one)])

    patch api_internal_pages_post_url(page_id: @page.id, id: posts(:one).id), params: { title: 'Hello world!', author_ids: [] }, as: :json
    posts(:one).reload

    assert_response :ok
    assert_equal 0, posts(:one).authors.count
  end

  test "should update authors of post" do
    sign_in_as(users(:lazaro_nixon))
    posts(:one).update(authors: [authors(:one)])

    patch api_internal_pages_post_url(page_id: @page.id, id: posts(:one).id), params: { title: 'Hello world!', author_ids: [authors(:without_name).id] }, as: :json
    posts(:one).reload

    assert_response :ok
    assert_equal 1, posts(:one).authors.count
    assert_equal authors(:without_name), posts(:one).authors.first
  end

  test "should schedule post and publish at scheduled_at timestamp" do
    sign_in_as(users(:lazaro_nixon))
    post_record = posts(:post_with_authors)

    scheduled_at = 5.hours.from_now.utc.change(usec: 0)

    assert_enqueued_jobs 0

    post api_internal_pages_post_publish_url(page_id: @page.id, post_id: post_record.id),
         params: { scheduled_at: scheduled_at },
         as: :json

    assert_response :ok
    post_record.reload
    assert post_record.scheduled?
    assert_equal scheduled_at, post_record.scheduled_at
    assert_not_nil post_record.job_id

    assert_enqueued_jobs 1

    travel_to scheduled_at

    perform_enqueued_jobs

    post_record.reload
    assert post_record.published?
  end

  test "should not schedule post if scheduled_at is in the past" do
    sign_in_as(users(:lazaro_nixon))
    post_record = posts(:post_with_authors)

    scheduled_at = 1.hour.ago.utc

    post api_internal_pages_post_publish_url(page_id: @page.id, post_id: post_record.id),
         params: { scheduled_at: scheduled_at },
         as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response['error'], "Schedule date must be in future"
  end

  test "should unschedule post" do
    sign_in_as(users(:lazaro_nixon))
    post_record = posts(:post_with_authors)

    # Manually schedule
    post_record.update!(status: :scheduled, scheduled_at: 1.day.from_now, job_id: '123')

    post api_internal_pages_post_unschedule_url(page_id: @page.id, post_id: post_record.id)

    assert_response :ok
    post_record.reload
    assert post_record.draft?
    assert_nil post_record.job_id
    assert_nil post_record.scheduled_at
  end

  test "cannot unschedule not scheduled post" do
    sign_in_as(users(:lazaro_nixon))
    post_record = posts(:post_with_authors)
    assert post_record.draft?

    post api_internal_pages_post_unschedule_url(page_id: @page.id, post_id: post_record.id)

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Post should be scheduled for unscheduling", json_response['error']
  end

  test "cannot unschedule if job id is nil" do
    sign_in_as(users(:lazaro_nixon))
    post_record = posts(:post_with_authors)
    post_record.update!(status: :scheduled, job_id: nil)

    post api_internal_pages_post_unschedule_url(page_id: @page.id, post_id: post_record.id)

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_equal "Post should have job id", json_response['error']
  end
end

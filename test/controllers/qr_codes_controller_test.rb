require "test_helper"

class QrCodesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }

  test "shows the printable QR code for a linked pet" do
    get pet_qr_code_url(pets(:one))

    assert_response :success
    assert_select ".qr-image svg"
    assert_includes response.body, qr_meal_log_url(qr_token: pets(:one).qr_token)
  end

  test "downloads an SVG" do
    get download_pet_qr_code_url(pets(:one))

    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_match(/attachment/, response.headers["content-disposition"])
  end

  test "administrator regeneration invalidates the old token" do
    old_token = pets(:one).qr_token
    patch regenerate_pet_qr_code_url(pets(:one))

    assert_redirected_to pet_qr_code_url(pets(:one))
    assert_not_equal old_token, pets(:one).reload.qr_token
  end

  test "cannot view another user's QR code page" do
    get pet_qr_code_url(pets(:two))
    assert_response :not_found
  end

  test "linked non-administrator cannot regenerate the QR token" do
    PetUser.create!(pet: pets(:one), user: users(:two), linked_at: Time.current, is_pet_admin: false)
    old_token = pets(:one).qr_token
    sign_out
    sign_in_as users(:two)

    patch regenerate_pet_qr_code_url(pets(:one))

    assert_redirected_to pet_qr_code_url(pets(:one))
    assert_equal old_token, pets(:one).reload.qr_token

    follow_redirect!
    assert_select "form[action=?]", regenerate_pet_qr_code_path(pets(:one)), count: 0
  end
end

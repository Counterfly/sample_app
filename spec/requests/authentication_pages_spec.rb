require 'spec_helper'

describe "AuthenticationPages" do

  subject { page }

  describe "signin page" do
    before { visit signin_path }

    it { should have_selector('h1',     text: 'Sign in') }
    it { should have_title('Sign in') }
  end

  describe "signin" do
    before { visit signin_path }

    describe "with invalid information" do
      before { click_button "Sign in" }

      it { should have_title('Sign in') }
      it { should have_error_message('Invalid') }
      it { should_not have_link('Profile') }
      it { should_not have_link('Settings') }

      describe "after visiting another page" do
        before { click_link "Home" }
        it { should_not have_selector('div.alert.alert-error') }
        #i think these two are the same
        it { should_not have_error_message('') }
      end
    end
    

    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in user }

      it { should have_selector('title',    text: user.name) }
      it { should have_link('Users',        href: users_path) }
      it { should have_link('Profile',      href: user_path(user)) }
      it { should have_link('Settings',     href: edit_user_path(user)) }
      it { should have_link('Sign out',     href: signout_path) }
      it { should_not have_link('Sign in',  href: signin_path) }
   
      describe "followed by signout" do
        before { click_link "Sign out" }
        it { should have_link('Sign in') }
      end
    end
  end


  describe "authorization" do
 
    describe "for signed in users" do
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in user }

      describe "using a 'new' action" do
        before { get new_user_path }
        specify { response.should redirect_to(root_path) }
      end

      describe "using a 'create' action" do
        before { post users_path }
        specify { response.should redirect_to(root_url) }
      end
    
      describe "micropost feed" do
        let!(:m1) { FactoryGirl.create(:micropost, user: user, content: "TEST") }
        it "should have 1 micropost" do
          visit root_url
          page.should have_content('1 micropost')
        end
        
        describe "can display multiple microposts" do
          let!(:m2) { FactoryGirl.create(:micropost, user: user, content: "TEST2") }
          
          it "should have 2 microposts" do
            visit root_url
            page.should have_content('2 microposts')
          end
        end
      end

      describe "pagination" do
        it "should paginate the feed" do
          31.times { FactoryGirl.create(:micropost, user: user, content: "Consectetur adiposcing elit") }
          visit root_path
          page.should have_selector('div.pagination')
        end
      end
    end 
 
    describe "as non-admin user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:non_admin) { FactoryGirl.create(:user) }

      before { sign_in non_admin }

      describe "submitting a DELETE request to the Users#destroy action" do
        before { delete user_path(user) }
        specify { response.should redirect_to(root_path) }
      end
    end 
    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }

     
      describe "when attempting to visit a protected page" do
        before do
          visit edit_user_path(user)
          valid_signin(user)
        end

        describe "after signing in" do
          it "should render the desired protected page" do
            page.should have_title('Edit user')
          end
        end
      end
     
      describe "in the Users controller" do
        
        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_title('Sign in') }
        end

        describe "submitting to the update action" do
          before { put user_path(user) }
          specify { response.should redirect_to(signin_path) }
        end

        describe "visiting the user index" do
          before { visit users_path }
          it { should have_title('Sign in') }
        end
      end

      describe "when attempting to visit a protected page" do
        before do
          visit edit_user_path(user)
          valid_signin(user)
        end

        describe "after signing in" do
          it "should render the desired protected page" do
            page.should have_title('Edit user')
          end

          describe "when signing in again" do
            before do
              delete signout_path
              visit signin_path
              valid_signin(user)
            end

            it "should render the default (profile) page" do
              page.should have_title(user.name)
            end
          end
        end
      end

      describe "in the Micropost controller" do
        
        describe "submitting to the create action" do
          before { post microposts_path }
          specify { response.should redirect_to(signin_path) }
        end

        describe "submitting to the destroy action" do
          before { delete micropost_path(FactoryGirl.create(:micropost)) }
          specify { response.should redirect_to(signin_path) }
        end
      end
    end

    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
      before {sign_in user }

      describe "visiting Users#edit page" do
        before { visit edit_user_path(wrong_user) }
        it { should_not have_title(full_title('Edit user')) }
      end

      describe "submitting a PUT request to the Users#update action" do
        before { put user_path(wrong_user) }
        specify { response.should redirect_to(root_url) }
      end
    end
  end

  describe "as admin user" do
    let(:admin) { FactoryGirl.create(:admin) }
    before do
      visit signin_path
      valid_signin admin
    end

    describe "admin should not be able to delete him/herself by submitting a DELETE request" do
      specify do
        expect { delete user_path(admin) }.to_not change(User, :count).by(-1)
      end
    end


  end
end

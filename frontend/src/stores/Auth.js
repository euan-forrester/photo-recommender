import vueAuth from '../auth';
import RepositoryFactory from '../repositories/repositoryFactory';

const FlickrRepository = RepositoryFactory.get('flickr');

export default {
  getters: {
    // We don't want vuex to cache the result of this function: we want it to be reevaluated every time.
    // So, return a function, and then this getter is called as a function rather than a property:
    // https://forum.vuejs.org/t/vuex-getter-not-re-evaluating-return-cached-data/55697/5
    isAuthenticated: () => () => vueAuth.isAuthenticated(),
  },

  actions: {
    async login() {
      await vueAuth.authenticate('flickr');
    },
    async logout() {
      // This just removes the auth token from our local storage. It doesn't call our API to delete the token from our database.
      //
      // The reason is that we're mixing and matching different styles of using vue-authenticate: above we're calling it with the
      // authenticate(<provider>) style, and below we're calling it in the login()/logout() style. There's no built-in way of
      // logging out a user who's been authenticated with the authenicate(<provider>) style: note that for example there's no
      // way of providing a logoutUrl.
      //
      // Here we can coax it into calling our logout url by passing it here in a params object. But it calls our API without
      // passing along our token or any other indication of who it's trying to log out. So we could store our current user ID
      // here and pass that along as well in the request body. But it just seems hacky and not in accordance with how the
      // lib is intended to operate.
      //
      // So, let's just call the logout URL manually from our Flickr repository
      try {
        await FlickrRepository.logoutUser();
      } finally {
        await vueAuth.logout();
      }
    },
  },
};

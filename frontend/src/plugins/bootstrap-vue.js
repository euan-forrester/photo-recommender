import Vue from 'vue';

// Reduce bundle size by pulling in only what we need from bootstrap.
// We could further optimize this by pulling in only the actual specific elements and directives
// that we use, but it would be more work for not a ton more gain.
// See here for more details: https://bootstrap-vue.js.org/docs/#tree-shaking-with-module-bundlers
//
// Note that this makes devving a bit annoying since anytime you want to try out a new
// type you have to add it here. So consider temporarily just using
//
//      import { BootstrapVue } from 'bootstrap-vue';
//      Vue.use(BootstrapVue);
//
// in those situations.

// Place all imports from 'bootstrap-vue' in a single import
// statement for optimal bundle sizes
import {
  LayoutPlugin,
  JumbotronPlugin,
  FormPlugin,
  FormInputPlugin,
  FormGroupPlugin,
  FormTextareaPlugin,
  ButtonPlugin,
  AlertPlugin,
  ImagePlugin,
  SpinnerPlugin,
  LinkPlugin,
  PopoverPlugin,
  CollapsePlugin,
  ProgressPlugin,
  CardPlugin,
} from 'bootstrap-vue';

import 'bootstrap/dist/css/bootstrap.min.css';
// import 'bootstrap-vue/dist/bootstrap-vue.css'; // Is this file necessary? The docs say it is, but I don't see anything missing without it: https://bootstrap-vue.js.org/docs/

Vue.use(LayoutPlugin);
Vue.use(JumbotronPlugin);
Vue.use(FormPlugin);
Vue.use(FormInputPlugin);
Vue.use(FormGroupPlugin);
Vue.use(FormTextareaPlugin);
Vue.use(ButtonPlugin);
Vue.use(AlertPlugin);
Vue.use(ImagePlugin);
Vue.use(SpinnerPlugin);
Vue.use(LinkPlugin);
Vue.use(PopoverPlugin);
Vue.use(CollapsePlugin);
Vue.use(ProgressPlugin);
Vue.use(CardPlugin);

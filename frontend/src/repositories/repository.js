import axios from 'axios';

const baseDomain = ''; // TODO: How do we set this properly?
const baseUrl = `${baseDomain}/api`;

export default axios.create({
  baseURL: baseUrl,
});

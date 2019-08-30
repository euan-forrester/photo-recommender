import axios from 'axios';

const baseDomain = 'http://localhost:4445'; // TODO: How do we set this properly?
const baseUrl = `${baseDomain}/`;

export default axios.create({
  baseURL: baseUrl,
});

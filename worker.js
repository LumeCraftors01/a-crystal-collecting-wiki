
export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Main simulator page
    if (url.pathname === "/") {
      url.pathname = "/Crystal%20Collecting%20Simulator.html";
    }

    // Community page
    if (
      url.pathname === "/community" ||
      url.pathname === "/community/"
    ) {
      url.pathname = "/community.html";
    }

    // Serve files from Cloudflare Assets
    return env.ASSETS.fetch(
      new Request(url.toString(), request)
    );
  },
};


export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // Main simulator
    if (url.pathname === "/") {
      url.pathname = "/Crystal Collecting Simulator.html";
    }

    // Community page
    if (
      url.pathname === "/community" ||
      url.pathname === "/community/"
    ) {
      url.pathname = "/community.html";
    }

    return env.ASSETS.fetch(
      new Request(url, request)
    );
  },
};

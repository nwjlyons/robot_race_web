import "../css/normalize.css"
import "../css/app.css"
import "phoenix_html"

import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";

import RaceTrack from "./hooks/race_track"
import CopyLink from "./hooks/copy_link"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

let liveSocket = new LiveSocket("/live", Socket, {
    hooks: {RaceTrack: RaceTrack, CopyLink: CopyLink},
    params: {_csrf_token: csrfToken},
});
liveSocket.connect();
window.liveSocket = liveSocket;

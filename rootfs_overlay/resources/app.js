
const state_url = '/camera_state'
const stop_url = '/stop'
const get_img_url = '/image'


setInterval(function () {
    fetch(state_url)
        .then(function (response) {
            return response.json();
        })
        .then(function (jsonResponse) {
            update_status(jsonResponse["status"], "status")
        });
}, 3000);

document.getElementById("start_btn").addEventListener("click", function () {
    console.log("subit-form");
    let time_interval = 30

    // convert user input from min to seconds
    let user_time_interval = document.getElementById("time_intervall").value;
    console.log(user_time_interval);

    user_time_interval *= 60;
    if (user_time_interval > time_interval) {
        time_interval = user_time_interval
    }

    document.getElementById("controls").submit();
    update_images(user_time_interval);
});

document.getElementById("stop_btn").addEventListener("click", function () {
    console.log("stop-btn");
    fetch(stop_url)
});

function update_status(state, id) {
    let status_bar = document.getElementById("status");
    if (state != status_bar.innerHTML) {

        status_bar.innerHTML = state;

        if (state === "running") {
            document.getElementById("status-div").classList.remove('is-warning');
            document.getElementById("status-div").classList.add('is-info');
        } else {
            document.getElementById("status-div").classList.remove('is-info');
            document.getElementById("status-div").classList.add('is-warning');
        }
    }
}

async function update_images(time_interval) {
    await Sleep(30 * 1000)
    getLastPicture()
    setInterval(function () {
        getLastPicture()

    }, time_interval * 1000);

    function Sleep(milliseconds) {
        return new Promise(resolve => setTimeout(resolve, milliseconds));
    }

}

function getLastPicture() {
    fetch(get_img_url)
        .then(function (response) {
            return response.json();
        })
        .then(function (jsonResponse) {
            console.log(jsonResponse)
            document.getElementById("last-image")
                .src = "data:image/jpeg;base64," + jsonResponse["image"];

            send_success = jsonResponse["send_success"]
            if (send_success == "true") {
                document.getElementById("send-status").innerHTML = "ok"
            } else {
                document.getElementById("send-status").innerHTML = "error"
            }
        });
}

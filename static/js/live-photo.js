(() => {
  const canHover = window.matchMedia("(hover: hover)").matches
    && !window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  document.querySelectorAll("[data-live-photo]").forEach((container) => {
    const video = container.querySelector("video");
    const button = container.querySelector(".live-photo-toggle");

    if (!video || !button) return;

    const setPlaying = (playing) => {
      container.classList.toggle("is-playing", playing);
      button.setAttribute("aria-pressed", String(playing));
      button.setAttribute("aria-label", playing ? "暂停实况照片" : "播放实况照片");
    };

    const play = async () => {
      try {
        await video.play();
        setPlaying(true);
      } catch {
        setPlaying(false);
      }
    };

    const reset = () => {
      video.pause();
      video.currentTime = 0;
      setPlaying(false);
    };

    button.addEventListener("click", () => {
      if (video.paused) {
        play();
      } else {
        reset();
      }
    });

    if (canHover) {
      container.addEventListener("pointerenter", play);
      container.addEventListener("pointerleave", reset);
    }

    video.addEventListener("pause", () => setPlaying(false));
    video.addEventListener("play", () => setPlaying(true));
  });
})();

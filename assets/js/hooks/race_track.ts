import Robot from "../robot"
import { cycle } from "../enum"

const colours = ["cyan", "magenta", "yellow", "white"];

export default {
    mounted(): void {
        this.game = { winning_score: 0, robots: [] };
        let canvas: HTMLCanvasElement = this.el;

        this.pushEvent("race_track_mounted", {})
        window.addEventListener('keyup', (event: KeyboardEvent) => {
            this.pushEvent("score_point", { source: "keyboard", key: event.key, code: event.code })
        })
        window.addEventListener('touchstart', (event: TouchEvent) => {
            this.pushEvent("score_point", { source: "touch" })
        })

        this.handleEvent("game_updated", (game) => {
            this.game = game;
            this.render(canvas);
        });
        window.addEventListener('resize', () => {
            this.render(canvas)
        });
    },
    render(canvas: HTMLCanvasElement): void {
        let bodyDimensions: DOMRect = document.body.getBoundingClientRect();
        canvas.width = bodyDimensions.width;
        canvas.height = bodyDimensions.height;

        let robotLength: number = Math.min(canvas.height / 10, canvas.width / 10);

        let columnWidth: number = canvas.width / this.game.robots.length;
        let rowHeight: number = (canvas.height - robotLength) / this.game.winning_score;

        for (let i: number = 0; i < this.game.robots.length; i++) {
            let robot = this.game.robots[i];
            let x: number = (i * columnWidth) + (columnWidth / 2) - (robotLength / 2);
            let y: number = (canvas.height - (rowHeight * robot.score)) - robotLength;
            new Robot(x, y, robotLength, cycle(colours, i), robot.name).render(canvas);
        }
    }
}

const fontFamily: string = "\'Press Start 2P\'"

const textColour: string = "#444";
const pupilColour: string = "#d3d3d3";
const scleraColour: string = "#2b2b2b";

class Eye {
    x: number
    y: number
    length: number

    constructor(x: number, y: number, length: number) {
        this.x = x;
        this.y = y;
        this.length = length;
    }

    render(canvas: HTMLCanvasElement): void {
        let ctx: CanvasRenderingContext2D = canvas.getContext('2d');
        // Sclera
        // https://en.wikipedia.org/wiki/Sclera
        ctx.fillStyle = scleraColour;
        let scleraLength = this.length;
        let scleraX = this.x;
        let scleraY = this.y;
        ctx.fillRect(scleraX, scleraY, scleraLength, scleraLength);
        // Pupil
        ctx.fillStyle = pupilColour;
        let pupilLength = scleraLength / 2.5;
        let pupilOffset = (scleraLength / 2) - pupilLength / 2;
        let pupilX = scleraX + pupilOffset;
        let pupilY = scleraY + pupilOffset;
        ctx.fillRect(pupilX, pupilY, pupilLength, pupilLength);
    }
}

class Body {
    x: number
    y: number
    length: number
    colour: string

    constructor(x: number, y: number, length: number, colour: string) {
        this.x = x;
        this.y = y;
        this.length = length;
        this.colour = colour;
    }

    render(canvas: HTMLCanvasElement): void {
        let ctx: CanvasRenderingContext2D = canvas.getContext('2d');
        this.renderRobotBodyWithBoxShadow(ctx, "white", 10);
        this.renderRobotBodyWithBoxShadow(ctx, "white", 15);
        this.renderRobotBodyWithBoxShadow(ctx, this.colour, 20);
        this.renderRobotBodyWithBoxShadow(ctx, this.colour, 40);
    }
    renderRobotBodyWithBoxShadow(ctx: CanvasRenderingContext2D, shadowColour: string, shadowBlur: number): void {
        ctx.shadowColor = shadowColour;
        ctx.shadowBlur = shadowBlur;
        ctx.fillStyle = this.colour;
        ctx.fillRect(this.x, this.y, this.length, this.length);
    }
}

class RobotName {
    x: number
    y: number
    length: number
    name: string

    constructor(x: number, y: number, length: number, name: string) {
        this.x = x;
        this.y = y;
        this.length = length;
        this.name = name;
    }

    render(canvas: HTMLCanvasElement): void {
        let ctx: CanvasRenderingContext2D = canvas.getContext('2d');
        let fontHeight = this.length / 6;
        ctx.fillStyle = textColour;
        ctx.shadowColor = "white";
        ctx.shadowBlur = 10;
        ctx.textAlign = "center";
        ctx.font = `${fontHeight}px ${fontFamily}`;
        ctx.fillText(this.name, this.x, this.y);
    }
}

export default class Robot {
    x: number
    y: number
    length: number
    colour: string
    name: string

    constructor(x: number, y: number, length: number, colour: string, name: string = "") {
        this.x = x;
        this.y = y;
        this.length = length;
        this.colour = colour;
        this.name = name;
    }

    render(canvas: HTMLCanvasElement): void {
        // Body
        new Body(this.x, this.y, this.length, this.colour).render(canvas);

        // Eyes
        let column = this.length / 11;
        let eyeLength = column * 4;
        let eyeYoffset = this.y + column * 1.75
        // Left eye
        let leftEyeX = this.x + column;
        new Eye(leftEyeX, eyeYoffset, eyeLength).render(canvas);
        // Right eye
        let rightEyeX = ((this.x + this.length) - eyeLength) - column;
        new Eye(rightEyeX, eyeYoffset, eyeLength).render(canvas);

        // Name
        let textX = this.x + (this.length / 2);
        let textY = (this.y + this.length) - column;
        new RobotName(textX, textY, this.length, this.name).render(canvas)
    }
}
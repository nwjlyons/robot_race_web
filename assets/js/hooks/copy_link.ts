export default {
    mounted(): void {
        this.el.addEventListener('click', () => {
            navigator.clipboard.writeText(this.el.dataset.copyLink)
        })
    }
}
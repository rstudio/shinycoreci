class InitComponent extends window.HTMLElement {
  constructor() {
    super();
    
    this.text = "default";
  }

  connectedCallback() {
    if (this.hasAttribute("init")) {
        this.text = this.getAttribute("init");
        this.removeAttribute("init");
    }
    this.render()
  }

  render() {
    this.innerText = this.text;
  }
}

window.customElements.define("init-component", InitComponent);

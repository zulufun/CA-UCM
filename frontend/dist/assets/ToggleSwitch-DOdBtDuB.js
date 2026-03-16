import{j as t}from"./radix-CPSHl3Lh.js";function h({checked:e=!1,onChange:a,disabled:n=!1,size:m="md",label:i,description:l,className:c=""}){const u={sm:{track:"w-8 h-[18px]",thumb:"w-3.5 h-3.5",translate:"translate-x-[14px]"},md:{track:"w-10 h-[22px]",thumb:"w-4 h-4",translate:"translate-x-[18px]"},lg:{track:"w-12 h-[26px]",thumb:"w-5 h-5",translate:"translate-x-[22px]"}},s=u[m]||u.md,o=()=>{!n&&a&&a(!e)},p=r=>{(r.key==="Enter"||r.key===" ")&&(r.preventDefault(),o())},x=t.jsx("button",{type:"button",role:"switch","aria-checked":e,disabled:n,onClick:o,onKeyDown:p,className:`
        relative inline-flex items-center shrink-0 rounded-full 
        transition-colors duration-200 ease-in-out
        focus:outline-none focus:ring-2 focus:ring-accent-primary-op40 focus:ring-offset-1 focus:ring-offset-bg-primary
        ${s.track}
        ${n?"opacity-50 cursor-not-allowed":"cursor-pointer"}
        ${e?"bg-accent-primary":"bg-bg-tertiary border border-border"}
      `,children:t.jsx("span",{className:`
          inline-block rounded-full shadow-sm
          transition-transform duration-200 ease-in-out
          ${s.thumb}
          ${e?`${s.translate} bg-white`:"translate-x-[3px] bg-text-tertiary"}
        `})});return i?t.jsxs("label",{className:`flex items-center gap-3 p-2 rounded-lg transition-colors
        ${n?"opacity-50 cursor-not-allowed":"cursor-pointer hover:bg-tertiary-op50"}
        ${c}
      `,onClick:r=>r.preventDefault(),children:[x,t.jsxs("div",{className:"flex-1",onClick:o,children:[t.jsx("p",{className:"text-sm text-text-primary font-medium",children:i}),l&&t.jsx("p",{className:"text-xs text-text-secondary",children:l})]})]}):t.jsx("div",{className:c,children:x})}export{h as T};

# my-lib-name

A nice introduction to what is going to achieve your lib


<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [my-lib-name](#my-lib-name)
  - [Installation](#installation)
  - [Usage](#usage)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation

```bash
npm i my-lib-name
```

## Usage

```typescript
@Component({
    selector:'my-component',
    imports:[my-lib-name]
    template:`
    <h1>{{title}}</h1>
    <my-lib-name/>
    `,
    styles:``

})
```
---
title: Render Markdown Test
tags: [neovim, markdown, test]
---

# Render Markdown Test

## 1. Heading Levels

# H1 Title

## H2 Title

### H3 Title

#### H4 Title

##### H5 Title

###### H6 Title

---

## 2. Text Styles

Normal text.

**Bold text**

_Italic text_

**_Bold and italic_**

~~Strikethrough~~

`inline code`

> This is a blockquote.
>
> Multiple quote lines.

---

## 3. Lists

### Unordered

- Item 1
- Item 2
  - Nested item
  - Nested item
- Item 3

### Ordered

1. First
2. Second
3. Third

### Task List

- [x] Done task
- [ ] Pending task
- [~] In progress task
- [!] Important task

---

## 4. Links and Images

[OpenAI](https://openai.com)

![Sample image](https://placehold.co/600x200)

---

## 5. Code Blocks

```lua
local function hello(name)
  print("Hello, " .. name)
end

hello("Neovim")
```

```tsx
export default function App() {
  return (
    <main>
      <h1>Hello Markdown</h1>
    </main>
  );
}
```

```python
def hello(name: str) -> None:
    print(f"Hello, {name}")

hello("Markdown")
```

---

## 6. Table

| Feature    | Status | Note             |
| ---------- | -----: | ---------------- |
| Headings   |     ✅ | Rendered         |
| Lists      |     ✅ | Nested supported |
| Code block |     ✅ | Highlighted      |
| Checkbox   |     ✅ | Icons            |
| Table      |     ✅ | Aligned          |

---

## 7. Callouts

> [!NOTE]
> This is a note callout.

> [!TIP]
> Useful tip goes here.

> [!IMPORTANT]
> Important information.

> [!WARNING]
> Be careful here.

> [!CAUTION]
> Dangerous operation.

---

## 8. Math-like Text

Inline: `E = mc^2`

Block:

```text
f(x) = x^2 + 2x + 1
```

---

## 9. HTML in Markdown

<div>
  <strong>Hello HTML</strong>
</div>

---

## 10. Long Section

Lorem ipsum dolor sit amet, consectetur adipiscing elit.

- Point A
- Point B
- Point C

> Nested quote example.
>
> - quoted list item
> - quoted list item

---

## End

This file is for testing `render-markdown.nvim`.

# Frontend Bank

**Baseline frontend patterns: No horrific stuff**

---

## Core Principles

1. **Accessibility First** - Works for everyone
2. **Performance Matters** - Fast load, smooth interactions
3. **Progressive Enhancement** - Works without JavaScript
4. **Semantic HTML** - Use the right elements
5. **Responsive Design** - Works on all screen sizes

---

## HTML Best Practices

### Semantic Elements
```html
<!-- BAD: Divs for everything -->
<div class="header">
  <div class="nav">
    <div class="link">Home</div>
  </div>
</div>

<!-- GOOD: Semantic elements -->
<header>
  <nav>
    <a href="/">Home</a>
  </nav>
</header>
```

### Accessibility
```html
<!-- Images need alt text -->
<img src="logo.png" alt="Company logo">

<!-- Forms need labels -->
<label for="email">Email</label>
<input id="email" type="email" name="email">

<!-- Buttons should be buttons -->
<button type="button">Click me</button>  <!-- Not <div onclick="..."> -->

<!-- Skip to content link -->
<a href="#main-content" class="skip-link">Skip to main content</a>
<main id="main-content">...</main>

<!-- Proper heading hierarchy -->
<h1>Page Title</h1>
  <h2>Section</h2>
    <h3>Subsection</h3>
<!-- Don't skip levels (h1 → h3) -->
```

---

## CSS Best Practices

### Naming Conventions
```css
/* Use BEM (Block Element Modifier) */
.card { }
.card__title { }
.card__image { }
.card--featured { }

/* Or use semantic class names */
.product-card { }
.product-card-title { }
.product-card-image { }
```

### Avoid Inline Styles
```html
<!-- BAD -->
<div style="color: red; font-size: 16px;">...</div>

<!-- GOOD -->
<div class="error-message">...</div>
```

### Use CSS Variables
```css
:root {
  --color-primary: #007bff;
  --color-error: #dc3545;
  --spacing-unit: 8px;
  --font-size-base: 16px;
}

.button {
  background: var(--color-primary);
  padding: calc(var(--spacing-unit) * 2);
}
```

### Mobile-First Responsive
```css
/* Default (mobile) styles */
.container {
  width: 100%;
  padding: 16px;
}

/* Tablet and up */
@media (min-width: 768px) {
  .container {
    max-width: 720px;
    margin: 0 auto;
  }
}

/* Desktop and up */
@media (min-width: 1024px) {
  .container {
    max-width: 960px;
  }
}
```

---

## JavaScript Best Practices

### Event Handling
```javascript
// BAD: Inline handlers
<button onclick="handleClick()">Click</button>

// GOOD: Event listeners
const button = document.querySelector('.button')
button.addEventListener('click', handleClick)

// GOOD: Event delegation (for dynamic content)
document.querySelector('.list').addEventListener('click', (e) => {
  if (e.target.matches('.item')) {
    handleItemClick(e.target)
  }
})
```

### DOM Manipulation
```javascript
// BAD: innerHTML with user content (XSS risk)
element.innerHTML = userInput

// GOOD: textContent for text
element.textContent = userInput

// GOOD: createElement for structure
const item = document.createElement('li')
item.textContent = text
list.appendChild(item)
```

### Async Operations
```javascript
// Modern async/await
async function fetchData() {
  try {
    const response = await fetch('/api/data')
    if (!response.ok) throw new Error('Fetch failed')
    const data = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching data:', error)
    throw error
  }
}

// Loading states
button.disabled = true
button.textContent = 'Loading...'
try {
  await fetchData()
} finally {
  button.disabled = false
  button.textContent = 'Submit'
}
```

---

## React Best Practices

### Component Structure
```jsx
// Functional components with hooks
function UserProfile({ userId }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchUser(userId).then(setUser).finally(() => setLoading(false))
  }, [userId])

  if (loading) return <div>Loading...</div>
  if (!user) return <div>User not found</div>

  return (
    <div className="user-profile">
      <h2>{user.name}</h2>
      <p>{user.bio}</p>
    </div>
  )
}
```

### Props and State
```jsx
// BAD: Mutating state
user.name = 'New name'
setUser(user)  // Won't trigger re-render!

// GOOD: New object
setUser({ ...user, name: 'New name' })

// BAD: Prop drilling through many levels
<Child1 data={data}>
  <Child2 data={data}>
    <Child3 data={data} />

// GOOD: Context for global state
const DataContext = createContext()
<DataContext.Provider value={data}>
  <Child3 />  // Uses useContext(DataContext)
</DataContext.Provider>
```

### Performance
```jsx
// Memoize expensive computations
const sortedItems = useMemo(
  () => items.sort((a, b) => a.name.localeCompare(b.name)),
  [items]
)

// Memoize callbacks
const handleClick = useCallback(
  (id) => { /* ... */ },
  [dependency]
)

// Lazy load components
const HeavyComponent = lazy(() => import('./HeavyComponent'))

<Suspense fallback={<div>Loading...</div>}>
  <HeavyComponent />
</Suspense>
```

---

## Forms Best Practices

### Accessible Forms
```html
<form>
  <!-- Label association -->
  <label for="username">Username</label>
  <input
    id="username"
    type="text"
    name="username"
    required
    aria-describedby="username-hint"
  >
  <span id="username-hint" class="hint">
    Must be 3-20 characters
  </span>

  <!-- Error messages -->
  <input
    id="email"
    type="email"
    aria-invalid="true"
    aria-describedby="email-error"
  >
  <span id="email-error" role="alert">
    Please enter a valid email
  </span>

  <!-- Submit button -->
  <button type="submit">Submit</button>
</form>
```

### Form Validation
```javascript
// HTML5 validation
<input type="email" required pattern="[^@]+@[^@]+\.[^@]+">

// JavaScript validation
form.addEventListener('submit', async (e) => {
  e.preventDefault()

  // Validate
  const email = form.email.value
  if (!email.includes('@')) {
    showError('Invalid email')
    return
  }

  // Submit
  try {
    await submitForm(new FormData(form))
    showSuccess('Form submitted')
  } catch (error) {
    showError(error.message)
  }
})
```

---

## Performance Optimization

### Images
```html
<!-- Responsive images -->
<img
  src="image-800w.jpg"
  srcset="image-400w.jpg 400w,
          image-800w.jpg 800w,
          image-1200w.jpg 1200w"
  sizes="(max-width: 600px) 400px,
         (max-width: 1000px) 800px,
         1200px"
  alt="Description"
  loading="lazy"
>

<!-- Modern formats with fallback -->
<picture>
  <source srcset="image.webp" type="image/webp">
  <source srcset="image.jpg" type="image/jpeg">
  <img src="image.jpg" alt="Description">
</picture>
```

### Scripts
```html
<!-- Defer non-critical scripts -->
<script src="analytics.js" defer></script>

<!-- Async for independent scripts -->
<script src="widget.js" async></script>

<!-- Critical CSS inline, rest deferred -->
<style>/* Critical CSS */</style>
<link rel="stylesheet" href="style.css" media="print" onload="this.media='all'">
```

### Loading States
```jsx
// Skeleton screens
function UserList() {
  if (loading) {
    return (
      <div className="skeleton">
        <div className="skeleton-item" />
        <div className="skeleton-item" />
        <div className="skeleton-item" />
      </div>
    )
  }
  return <div>{users.map(...)}</div>
}
```

---

## Common Anti-Patterns

### ❌ Don't Do This

```html
<!-- Non-semantic divs -->
<div class="button" onclick="...">

<!-- Missing alt text -->
<img src="important.jpg">

<!-- Tables for layout -->
<table><tr><td>Layout</td></tr></table>

<!-- Inline styles everywhere -->
<div style="color: red; font-size: 14px; margin: 10px;">
```

```javascript
// Global variables
var userData = {}  // Pollutes global scope

// Synchronous XHR
const xhr = new XMLHttpRequest()
xhr.open('GET', url, false)  // Blocks browser!

// Deeply nested callbacks
getData((data) => {
  processData(data, (result) => {
    saveResult(result, (saved) => {
      // Callback hell
    })
  })
})
```

```css
/* !important everywhere */
.text { color: red !important; }

/* IDs for styling */
#header { }  /* Use classes */

/* Magic numbers */
.box { margin-left: 73px; }  /* Why 73? */
```

---

## Accessibility Checklist

- [ ] All images have alt text?
- [ ] Form inputs have labels?
- [ ] Keyboard navigation works?
- [ ] Color contrast ratio ≥ 4.5:1?
- [ ] Focus indicators visible?
- [ ] ARIA labels for icon buttons?
- [ ] Heading hierarchy correct?
- [ ] Screen reader tested?

---

## Tools & Testing

### Linting
```json
// ESLint + Prettier
{
  "extends": ["eslint:recommended", "prettier"],
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "error"
  }
}
```

### Accessibility Testing
```bash
# Lighthouse (Chrome DevTools)
# - Performance score
# - Accessibility score
# - Best practices score

# axe DevTools extension
# - Automated accessibility checks
```

### Performance Testing
```javascript
// Web Vitals
import { getCLS, getFID, getFCP, getLCP, getTTFB } from 'web-vitals'

getCLS(console.log)  // Cumulative Layout Shift
getFID(console.log)  // First Input Delay
getLCP(console.log)  // Largest Contentful Paint
```

---

## When to Use This Bank

✅ Building new UI components
✅ Reviewing frontend code
✅ Setting up new frontend project
✅ Debugging accessibility issues
✅ Optimizing performance

---

**Remember: Good frontend is accessible, fast, and works for everyone.**

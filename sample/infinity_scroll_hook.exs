defmodule InfinityScrollHook do
  @moduledoc """
  Adapted from the live view hook example.

  ```js
  Hooks.InfiniteScroll = {
    page() { return this.el.dataset.page },
    mounted(){
      this.pending = this.page()
      window.addEventListener("scroll", e => {
        if(this.pending == this.page() && scrollAt() > 90){
          this.pending = this.page() + 1
          this.pushEvent("load-more", {})
        }
      })
    },
    updated(){ this.pending = this.page() }
  }
  ```
  """

  defun new() do
    %{
      page: &page/1,
      mounted: &mounted/1,
      updated: &updated/1
    }
  end

  defunp page(@self = self) do
    self.el.dataset.page
  end

  defunp mounted(@self = self) do
    Object.set(self, :pending, Object.send(self, :page))

    Window.add_event_listener(:scroll, fn e ->
      if self.pending == Object.send(self, :page) && scroll_at() > 90 do
        Object.set(self, :pending, Object.send(self, :page) + 1)
        Object.send(self, :pushEvent, ["load-more", %{}])
      end
    end)
  end

  defun updated(@self = self) do
    Object.set(self, :pending, Object.send(self, :page))
  end
end

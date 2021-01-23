{%- if theme.follow_me %}

  <div class="followme">
    <div class="social-list">
      {%- for name, value in theme.follow_me %}
        {%- set link = value.split('||')[0] | trim %}
        {%- set icon = value.split('||')[1] | trim %}

        <div class="social-item">
            <img src="{{link}}" width="200" height="200">
            <center><strong>{{ name }}</strong></center>
        </div>
      {%- endfor %}
    </div>
  </div>
{%- endif %}
